# Troubleshooting

Erweiterte Diagnose-Hinweise zu typischen Fehlerbildern. Die kompakte
Tabelle in [`auth-setup.md`](auth-setup.md#6-troubleshooting) deckt die
haeufigsten Faelle; hier gibt's mehr Tiefe und weitere Kategorien.

Format pro Eintrag: **Symptom** → **Ursache(n)** → **Diagnose** → **Fix**.

---

## 1. Auth & Connectivity

### 1.1 `kinit: Preauthentication failed`

**Symptom:** `kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL` schlaegt
mit `Preauthentication failed` fehl.

**Ursache(n):**
- Keytab-Passwort != AD-Passwort (klassisch nach `ktpass`-Aufruf, der das
  AD-PW dreht)
- Encryption-Type-Mismatch (Keytab nutzt RC4, AD lehnt RC4 ab)
- Account-Lockout durch wiederholte fehlgeschlagene Versuche

**Diagnose:**
```bash
# Welche Encryption-Types liegen im Keytab?
klist -kte /etc/krb5.keytab

# Was akzeptiert AD fuer den User?
# Auf Windows-Domain-Controller:
#   Get-ADUser svc-tofu -Properties msDS-SupportedEncryptionTypes
```

**Fix:**
- Keytab via `ktutil` neu erzeugen (Linux) — laesst AD-PW unangetastet
- Oder PW in AD auf den Wert setzen, der zum Keytab passt
- Sicherstellen, dass `KerberosEncryptionType = AES256` am Account
  gesetzt ist

### 1.2 `kinit: KDC reply did not match expectations`

**Symptom:** kinit kommt durch zum KDC, scheitert dann am Reply-Vergleich.

**Ursache(n):**
- Realm-Name in `/etc/krb5.conf` falsch geschrieben (oft Klein- statt
  Grossbuchstaben)
- Account-Principal vs UPN-Mismatch (AD-Konto hat anderen UPN als der
  Principal im kinit-Befehl)

**Diagnose:**
```bash
KRB5_TRACE=/dev/stdout kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL 2>&1 |
    grep -E "realm|UPN"
```

**Fix:** Realm in `krb5.conf` GROSSGESCHRIEBEN, exakt zur AD-Domain,
inkl. `[domain_realm]`-Mapping. UPN des Accounts in AD pruefen
(`Get-ADUser -Properties UserPrincipalName`).

### 1.3 `curl: (60) SSL certificate problem`

**Symptom:** TLS-Handshake schlaegt fehl beim Aufruf des AdminService.

**Ursache(n):** Internal-CA nicht im System-Trust-Store, oder
Site-Zertifikat ist abgelaufen / SAN passt nicht zum Hostnamen.

**Diagnose:**
```bash
# Zertifikat anzeigen
openssl s_client -connect sccm.corp.local:443 -servername sccm.corp.local </dev/null 2>/dev/null |
    openssl x509 -noout -subject -issuer -dates -ext subjectAltName

# Wo ist die System-CA-Bundle?
ls -la /etc/ssl/certs/ca-certificates.crt   # Debian
ls -la /etc/pki/tls/certs/ca-bundle.crt     # RHEL
```

**Fix:** Internal-CA-Cert installieren und CA-Bundle aktualisieren —
Schritt 4c in [`auth-setup.md`](auth-setup.md).

### 1.4 `401 Unauthorized` trotz erfolgreichem `kinit`

**Symptom:** kinit liefert TGT, klist zeigt es, aber `curl --negotiate
... /AdminService/...` bekommt 401.

**Ursache(n):**
- URL-Hostname != SPN-Hostname (z.B. URL nutzt Short-Name, SPN ist FQDN
  oder umgekehrt)
- Negotiate fallt back auf NTLM, das die AdminService-Konfig blockiert
- Zwei SPNs auf unterschiedlichen Konten registriert

**Diagnose:**
```bash
# Pruefe ob TGS holt:
kvno HTTP/sccm.corp.local@DOMAIN.LOCAL

# Was schickt curl konkret?
curl -v --negotiate -u : https://sccm.corp.local/AdminService/wmi/SMS_Site 2>&1 |
    grep -E "Authorization|WWW-Auth"
```

**Fix:** Auf Windows-DC `setspn -L <site-server>` pruefen, ggf. Duplikate
mit `setspn -X` finden. URL und SPN exakt zur gleichen FQDN-Form bringen.

### 1.5 `403 Forbidden`

**Symptom:** Auth funktioniert, AdminService liefert 403.

**Ursache(n):** RBAC-Rolle des Service-Account hat zu engen Scope, oder
gar keine Rolle.

**Fix:** ConfigMgr-Console → Administration → Security → Administrative
Users → Service-Account: Rolle und Scope pruefen. Mindestens
"Read-only Analyst" auf "All Systems" / "All Users".

---

## 2. ConfigMgr-spezifisch

### 2.1 AdminService antwortet `500 Internal Server Error`

**Symptom:** Beliebiger AdminService-Call gibt 500.

**Ursache(n):** SMS_REST_PROVIDER-Service auf dem Site-Server haengt;
SMS-Provider-WMI-Layer liefert Fehler hoch; IIS-AppPool gestoppt.

**Diagnose:**
```powershell
# Auf dem Site-Server:
Get-Service SMS_REST_PROVIDER
Get-WebAppPoolState -Name 'SMS Admin Service Pool'   # AppPool-Name kann abweichen

# Logs:
Get-Content "$env:SMS_LOG_PATH\AdminService.log" -Tail 50
```

**Fix:** Service neustarten (`Restart-Service SMS_REST_PROVIDER`) oder
AppPool. Wenn das Provider-Log Fehler zeigt, oft Folge eines anderen
Site-Problems (DB-Connection, Site-Server-Recovery).

### 2.2 `value`-Array leer trotz existierendem Device

**Symptom:**
```bash
curl ".../wmi/SMS_R_System?\$filter=Name eq 'PC123'"
# {"value": []}
```
obwohl der Rechner in der Console klar zu sehen ist.

**Ursache(n):** RBAC-Scope filtert ihn raus (Service-Account sieht nur
bestimmte Collections), oder Hostname-Casing-Mismatch (sollte case-
insensitiv sein, aber bei manchen Special-Cases nicht).

**Diagnose:**
```bash
# Gleiche Query mit einem Account mit Full-Admin-RBAC:
curl --negotiate -u : ".../wmi/SMS_R_System?\$filter=Name eq 'PC123'"

# Wildcard-Suche zur Validierung:
curl --negotiate -u : ".../wmi/SMS_R_System?\$filter=startswith(Name,'PC')&\$top=5"
```

**Fix:** RBAC-Scope erweitern oder Custom-Role mit den richtigen
Collection-Limiting-Settings.

### 2.3 View-Schema nach Major-Upgrade gebrochen (Variante 04)

**Symptom:** `sqlcmd`-Query schlaegt mit `Invalid column name`-Fehler
fehl, z.B. nach ConfigMgr 2503 → 2509.

**Ursache(n):** Microsoft hat View-Spalten umbenannt/entfernt. Views
sind dokumentiert, aber nicht formal versioniert.

**Diagnose:**
```bash
# Aktuelles Schema gegen die genutzte Spalte
./05-sql-direct-linux/Demo/090-discover-views.sh v_R_System schema | grep <SpaltenName>
```

**Fix:** Query an neues Schema anpassen. Pflicht-Hygiene: pro Major-
Upgrade einmal die genutzten Spalten gegen das aktuelle Schema laufen
lassen.

### 2.4 Cmdlet-Package: `Version mismatch` (Variante 07)

**Symptom:** `Get-CMDevice` wirft Versionsfehler beim ersten Cmdlet-
Aufruf.

**Ursache:** Das exportierte Cmdlet-Package stammt aus einer alteren
ConfigMgr-CB als die laufende Site. Die Cmdlets pruefen Site-Version
beim Start.

**Fix:** Package aus einer Console mit passender Version neu erzeugen
(siehe garytown-CreateCMPowerShellModulePackage.ps1).

### 2.5 `Get-CMDevice` ist langsam (Variante 04/07)

**Symptom:** `Get-CMDevice` braucht Minuten fuer eine Liste.

**Ursache:** `-Fast` fehlt — alle Lazy-Properties werden nachgeladen.

**Fix:** Immer `Get-CMDevice -Fast` nutzen, wenn nicht alle Properties
gebraucht werden. Mit `Select-Object` nachfiltern.

---

## 3. OpenTofu / Pipeline

### 3.1 Tofu-Wait laeuft in Endlos-Schleife / Timeout

**Symptom:** `tofu apply` haengt am `null_resource.wait_for_configmgr`,
laeuft bis Timeout.

**Ursache(n):**
- Task-Sequence ist tatsaechlich noch nicht fertig (warten ist korrekt)
- Task-Sequence ist gescheitert, aber Status wurde nicht zu "Failed"
- Hostname-Mismatch (Tofu uebergibt anderen Namen als ConfigMgr kennt)
- Client kommt nie ins "Active=1" hoch (Boundary-Group-Problem)

**Diagnose:** Gleiches Skript mit Verbose ausfuehren:
```bash
pwsh ./01-adminservice-pwsh-linux/Wait-ConfigMgrDeployed.ps1 \
    -ComputerName PC123 -SmsProvider sccm.corp.local -SiteCode P01 \
    -TimeoutSeconds 60 -Verbose
```

In ConfigMgr-Console: TS-Deployment-Monitoring der Resource ansehen.

**Fix:** Symptom abhaengig — TS reparieren, Boundary-Group fixen, oder
bei Hostname-Mismatch die Tofu-Variable korrigieren.

### 3.2 Tofu wirft `Failed to install module`

**Symptom:** `tofu init` in `examples/full-vm-rollout/` schlaegt fehl mit
`Could not load module "../../01-adminservice-pwsh-linux"`.

**Ursache:** Module-Source-Pfad relativ zum aufrufenden Projekt-Root,
nicht zur main.tf.

**Fix:** Pfad mit `./../../...` praezisieren, oder Module im Tofu-
Registry-Format quellen (z.B. `source = "github.com/monoeagle/...//modules/..."`).

### 3.3 State zeigt deployed, ConfigMgr nicht

**Symptom:** `tofu state show` sagt `null_resource.wait_for_configmgr`
existiert, ConfigMgr-Console zeigt aber kein deployed-Device.

**Ursache:** Tofu-State und MECM-Realitaet sind entkoppelt. Wait war
beim ersten Apply erfolgreich, danach hat jemand die Resource in MECM
geloescht.

**Diagnose:** `tofu state show null_resource.wait_for_configmgr` zeigt
nur die `triggers`-Map, keine Live-MECM-Daten.

**Fix:** `tofu taint null_resource.wait_for_configmgr` und neu apply,
damit der Wait nochmal laeuft. Drift-Detection via `null_resource` ist
nicht moeglich — das ist eine bewusste Scope-Entscheidung des Repos
(Skript-Helper statt eigener Provider). Wer Read-/Drift-Funktion
braucht, muesste einen Tofu-Provider bauen.

### 3.4 Konkurrierende Apply-Runs

**Symptom:** Zwei CI-Pipelines triggern `tofu apply` parallel, beide
warten auf denselben Rechner — einer haengt am Lock.

**Fix:** Tofu-State-Locking via Backend (z.B. S3 + DynamoDB, GitLab,
Terraform Cloud). Niemals File-Backend in Multi-User-Setups.

---

## 4. Skript- / Encoding-Probleme

### 4.1 PowerShell 5.1: `Token '?' was unexpected at this point`

**Symptom:** Script wirft Parse-Error in 5.1, laeuft in pwsh 7 sauber.

**Ursache:** pwsh-7-only-Operator (`??`, `?.`, ternaer `?:`).

**Fix:** 5.1-Compat-Variante aus `windows-pwsh5/`-Folder benutzen, oder
`if/else`-Workaround. Patterns in
[`01-adminservice-pwsh-linux/windows-pwsh5/README.md`](../01-adminservice-pwsh-linux/windows-pwsh5/README.md) oder Block `02-adminservice-pwsh-windows` nutzen.

### 4.2 Bash: `$'\r': command not found`

**Symptom:** bash-Skript scheitert mit kryptischen `\r`-Errors.

**Ursache:** Skript wurde mit CRLF-Lineendings gespeichert (Windows-
Editor) und wird auf Linux ausgefuehrt.

**Diagnose:**
```bash
file ./script.sh    # zeigt 'CRLF' wenn Problem
```

**Fix:**
```bash
sed -i 's/\r$//' script.sh
# Oder einmalig im Repo:
git config core.autocrlf input
git add --renormalize .
```

### 4.3 sqlcmd: `column not found` trotz korrektem Spaltennamen

**Symptom:** `Invalid column name 'Name0'` obwohl `v_R_System` die Spalte hat.

**Ursache:** Falsche Datenbank — `master` statt `CM_<SiteCode>`.

**Fix:** `-d CM_P01` setzen, nicht weglassen.

### 4.4 Sonderzeichen im Hostnamen

**Symptom:** Devices mit Umlaut/Cyrillic im Namen werden nicht gefunden.

**Ursache:** SQL-String ist VARCHAR statt NVARCHAR, oder REST-URL nicht
URL-encoded.

**Fix:**
- SQL: `WHERE Name0 = N'PCÄÖÜ'` (N-Praefix)
- REST: `[uri]::EscapeDataString` / `--data-urlencode`

### 4.5 jq: `Cannot index null with string`

**Symptom:** AdminService liefert `{}` ohne `value`-Array, `jq '.value[]'`
crasht.

**Fix:** Default-Pattern `jq '.value // [] | .[]'`.

---

## 5. Diagnose-Checkliste fuer "irgendwas geht nicht"

Wenn unklar, in dieser Reihenfolge durchgehen:

1. **Network:** `curl -I https://sccm.corp.local/AdminService/` — kommt
   die Antwort durch?
2. **TLS:** `openssl s_client` — Zertifikat ok?
3. **Kerberos:** `klist` — TGT vorhanden? Wenn nicht: `kinit -kt`.
4. **TGS:** `kvno HTTP/<sms-provider>@<REALM>` — Service-Ticket holbar?
5. **Auth:** `curl --negotiate ... /SMS_Site` — kommt 200 zurueck?
6. **RBAC:** `curl ... /SMS_R_System?$top=1` — sieht der Account
   ueberhaupt Devices?
7. **Konkrete Query:** erst dann das Wait-/Demo-Skript.

Jeder Schritt isoliert eine Ebene. Wenn 1-6 gruen sind und 7 rot, ist
das Problem definitiv im Skript / der Query.
