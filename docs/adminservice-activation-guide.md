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
