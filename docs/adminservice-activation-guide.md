# AdminService aktivieren — Schritt-für-Schritt

Voraussetzung: MECM Current Branch **1810 oder neuer**, Admin-Zugriff auf die Konsole.

---

## Schritt 1 — MECM-Konsole öffnen und zur Site navigieren

1. MECM-Konsole starten
2. Unten links das Workspace-Panel aufklappen und **Administration** auswählen

   ```
   [ Assets and Compliance    ]
   [ Software Library         ]
   [ Monitoring               ]
   [▶ Administration          ]  ← hier klicken
   ```

3. Im linken Baum aufklappen:

   ```
   Administration
   └── Site Configuration
       └── Sites            ← hier klicken
   ```

4. Im mittleren Bereich erscheint die Liste der Sites (z. B. `P01 - Primary Site`).
   Die gewünschte Site **markieren** (einmal anklicken, nicht doppelt).

---

## Schritt 2 — Site-Properties öffnen

Zwei Wege führen zu den Properties:

- **Ribbon (oben):** Reiter `Home` → Gruppe `Properties` → Schaltfläche **Properties**
- **Kontextmenü:** Rechtsklick auf die Site → **Properties**

Es öffnet sich das Fenster `<SiteName> Properties`.

---

## Schritt 3 — Enhanced HTTP aktivieren

1. Im Properties-Fenster den Reiter **Communication Security** auswählen.

   > Ältere CB-Versionen (vor ~2103) nennen den Reiter manchmal **Client Computer
   > Communication** — der Inhalt ist identisch.

2. Im unteren Bereich des Reiters findet sich der Abschnitt
   **"HTTP site systems"** (oder ähnlich). Dort die Checkbox aktivieren:

   ```
   [✓] Use Configuration Manager-generated certificates for HTTP site systems
   ```

   Das ist **Enhanced HTTP (eHTTP)**. MECM stellt daraufhin selbstsignierte
   Zertifikate für alle HTTP-Site-Systeme aus — darunter der IIS auf dem
   SMS-Provider-Server, der für den AdminService benötigt wird.

3. **OK** klicken.

   > Falls eine Warnung erscheint ("This will cause site systems to restart
   > their roles"), bestätigen. Der `SMS_REST_PROVIDER`-Dienst startet neu —
   > das ist gewollt.

---

## Schritt 4 — Warten auf Zertifikat-Verteilung

MECM verteilt die Zertifikate asynchron über die Site-Komponenten.
Erfahrungswert: **2–5 Minuten** bis der AdminService zuverlässig antwortet.

Fortschritt prüfen — auf dem Site-Server in `C:\Program Files\Microsoft
Configuration Manager\Logs\` die folgenden Log-Dateien im **CMTrace**
(oder `Get-Content -Wait`) beobachten:

| Log-Datei | Was sie zeigt |
|---|---|
| `sitecomp.log` | Site-Komponenten-Manager, startet SMS_REST_PROVIDER neu |
| `restprovider.log` | AdminService selbst; zeigt ob er erfolgreich gestartet ist |

Relevante Zeilen in `restprovider.log`:

```
REST Provider started successfully
Listening on https://+:443/AdminService/
```

---

## Schritt 5 — Dienst auf dem Site-Server prüfen

Auf dem **SMS-Provider-Server** (meist der Site-Server selbst) PowerShell
als Admin öffnen:

```powershell
# Dienststatus
Get-Service -Name SMS_REST_PROVIDER

# Erwartet:
# Status   Name               DisplayName
# ------   ----               -----------
# Running  SMS_REST_PROVIDER  ConfigMgr REST Provider
```

Falls der Dienst `Stopped` ist:

```powershell
Start-Service SMS_REST_PROVIDER
```

IIS-Anwendung prüfen:

```powershell
Import-Module WebAdministration
Get-WebApplication -Name AdminService

# Erwartet eine Zeile mit PhysicalPath auf CM AdminUI\WebSite
```

---

## Schritt 6 — Endpoint vom Client aus testen

### Von einem Windows-Client / Workstation

```powershell
# Verbindungstest (nutzt automatisch Windows-Auth)
$uri = 'https://<sms-provider-fqdn>/AdminService/wmi/SMS_Site'
Invoke-RestMethod -Uri $uri -UseDefaultCredentials | Select-Object -Expand value
```

Erwartetes Ergebnis: JSON mit Site-Informationen (`SiteCode`, `SiteName`, …).

### Von einem Linux-Rechner (mit Kerberos-Ticket)

```bash
# Zuerst Ticket holen
kinit svc-tofu@DOMAIN.LOCAL

# Dann testen
curl --negotiate -u : \
  -H 'Accept: application/json' \
  https://<sms-provider-fqdn>/AdminService/wmi/SMS_Site
```

### Schnelltest ohne Auth (nur Erreichbarkeit)

```bash
curl -k -I https://<sms-provider-fqdn>/AdminService/
```

| HTTP-Antwort | Bedeutung |
|---|---|
| `401 Unauthorized` | Endpoint aktiv, Auth fehlt — **korrekt** |
| `200 OK` | Endpoint aktiv, Auth durchgelassen |
| `403 Forbidden` | eHTTP nicht aktiv oder Zertifikat-Problem |
| `404 Not Found` | IIS-Anwendung fehlt |
| Keine Antwort / Timeout | Firewall oder Dienst gestoppt |

---

## Häufige Stolperfallen

### "Communication Security"-Reiter fehlt

Tritt auf, wenn man die CAS (Central Administration Site) statt der Primary
Site ausgewählt hat. eHTTP muss auf der **Primary Site** aktiviert werden.

### Checkbox ist ausgegraut

Die Site ist möglicherweise bereits auf **HTTPS only** konfiguriert — dann
ist eHTTP nicht nötig, der AdminService läuft bereits. Testweise
`curl -k -I https://<fqdn>/AdminService/` ausführen.

### Dienst SMS_REST_PROVIDER existiert nicht (nicht nur gestoppt, sondern gar nicht vorhanden)

Das bedeutet, dass die SMS-Provider-Rolle auf diesem Server entweder nie
vollständig installiert wurde oder die MECM-Version älter als CB 1810 ist.

**Diagnose — Schritt für Schritt:**

```powershell
# 1. Existiert der Dienst überhaupt?
Get-Service -Name SMS_REST_PROVIDER -ErrorAction SilentlyContinue
# Kein Output → Dienst nicht installiert

# 2. MECM-Version prüfen (muss 1810 oder neuer sein)
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\SMS\Setup" | Select-Object "Full Version"

# 3. Ist die SMS-Provider-Rolle auf diesem Server registriert?
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\SMS\Providers" -ErrorAction SilentlyContinue
# Kein Ergebnis → SMS Provider nicht auf diesem Server installiert
```

**Fall A — MECM-Version älter als 1810**

Der AdminService existiert nicht. Einziger Fix: MECM auf CB 1810 oder neuer
aktualisieren. Bis dahin Variante 04, 05, 06 oder 07 aus der OVERVIEW nutzen.

**Fall B — SMS-Provider-Rolle nicht auf diesem Server installiert**

Die Rolle muss erst hinzugefügt werden:

1. MECM-Konsole → **Administration → Site Configuration →
   Servers and Site System Roles**
2. Rechtsklick auf den gewünschten Server →
   **Add Site System Roles**
3. Im Wizard **SMS Provider** anhaken → Wizard abschließen
4. `sitecomp.log` beobachten bis die Rolle als installiert gemeldet wird
5. Danach `Get-Service SMS_REST_PROVIDER` erneut prüfen

**Fall C — Rolle laut Konsole installiert, Dienst aber trotzdem fehlt**

Die Installation ist inkonsistent. MECM-Setup im Repair-Modus ausführen:

```
C:\Program Files\Microsoft Configuration Manager\bin\X64\setup.exe
→ "Perform site maintenance or reset this site"
→ "Reset site with no configuration changes"
```

Nach dem Repair:

```powershell
# Dienst sollte jetzt existieren und laufen
Get-Service SMS_REST_PROVIDER
```

---

### HTTP 403 nach eHTTP-Aktivierung

IIS hat das neue Zertifikat noch nicht gebunden. Warten (bis 5 min) oder
auf dem Site-Server:

```powershell
Restart-Service SMS_REST_PROVIDER
```

### HTTP 401 dauerhaft (Auth schlägt fehl)

Der Service-Account hat keine ConfigMgr-RBAC-Rolle. Mindestanforderung:

**Administration → Security → Administrative Users → Add**
- Objekt: Service-Account
- Rolle: `Read-only Analyst`
- Scope: `All instances` (oder eingeschränkter Scope auf relevante Collections)

### AdminService-Anwendung fehlt im IIS (404 / keine Seite sichtbar)

Wenn in IIS Manager unter "Default Web Site" keine `AdminService`-Anwendung
erscheint — oder die "Default Web Site" selbst fehlt — gibt es drei mögliche
Ursachen:

**a) eHTTP gerade erst aktiviert — noch nicht deployed**

MECM deployed die IIS-Anwendung asynchron nach dem Speichern der
Communication-Security-Einstellung. Auf dem Site-Server `sitecomp.log`
beobachten:

```powershell
Get-Content "C:\Program Files\Microsoft Configuration Manager\Logs\sitecomp.log" -Wait -Tail 30
```

Zeilen die auf erfolgreiche Einrichtung hindeuten:

```
Installing SMS_REST_PROVIDER ...
SMS_REST_PROVIDER installed successfully
```

Wenn diese Zeilen erscheinen, danach nochmals IIS Manager neu laden (F5).

**b) IIS-Rolle fehlt auf dem Server**

Der AdminService setzt IIS voraus. Prüfen ob IIS installiert ist:

```powershell
Get-WindowsFeature -Name Web-Server, Web-Asp-Net45, Web-Windows-Auth |
    Select-Object Name, InstallState
```

Alle drei müssen `Installed` sein. Falls nicht:

```powershell
Install-WindowsFeature -Name Web-Server, Web-Asp-Net45, Web-Windows-Auth -IncludeManagementTools
```

Anschließend auf dem MECM-Server den Site-Component-Manager-Dienst neu
starten, damit MECM die IIS-Konfiguration erneut ausrollt:

```powershell
Restart-Service SMS_SITE_COMPONENT_MANAGER
```

Danach wieder `sitecomp.log` beobachten.

**c) SMS-Provider-Rolle defekt oder nie installiert**

Wenn IIS vorhanden ist, aber die Anwendung dauerhaft fehlt (auch nach
Warten und Log-Prüfung), muss die SMS-Provider-Rolle repariert werden:

1. MECM-Konsole → **Administration → Site Configuration → Servers and
   Site System Roles**
2. Den betroffenen Server auswählen
3. Rechtsklick auf **SMS Provider** → **Remove Role**
4. Kurz warten, dann erneut Rechtsklick auf den Server →
   **Add Site System Roles** → SMS Provider hinzufügen
5. Wizard durchlaufen, danach `sitecomp.log` beobachten

Alternativ: MECM-Setup im Repair-Modus ausführen:

```
C:\Program Files\Microsoft Configuration Manager\bin\X64\setup.exe
→ "Perform site maintenance or reset this site"
→ "Reset site with no configuration changes"
```

Das repariert IIS-Bindings und Anwendungen ohne Konfigurationsverlust.

---

### Zertifikat wird vom Linux-Client nicht akzeptiert

Das selbstsignierte Zertifikat der internen CA muss dem System-Trust-Store
hinzugefügt werden:

```bash
# CA-Zertifikat (als .crt) in den Trust-Store importieren
sudo cp interne-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Oder für schnelle Tests: `curl -k` / `[System.Net.ServicePointManager]::ServerCertificateValidationCallback`
(nur Dev/Test, nie Produktion).

---

## Übersicht der beteiligten Komponenten

```
MECM-Konsole
└── Administration
    └── Site Configuration
        └── Sites → Properties → Communication Security
            └── [✓] Use CM-generated certificates   ← dieser Haken aktiviert eHTTP

Site-Server
├── IIS
│   └── Default Web Site
│       └── AdminService  (virtuelle Anwendung)
├── Dienst: SMS_REST_PROVIDER
└── Logs: C:\...\Logs\restprovider.log
```
