# 01 — AdminService via PowerShell (Linux)

Linux-Runner ruft die AdminService REST API von ConfigMgr direkt mit `Invoke-RestMethod` auf.
Authentifizierung via Kerberos (kinit + Keytab).

## Voraussetzungen

- PowerShell 7 (`pwsh`) auf dem Runner
- AdminService Endpoint erreichbar: `https://<smsprovider>/AdminService/`
- Kerberos: Keytab gemounted, `kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL` läuft vor dem Tofu-Run
- CA-Zertifikat des SMS-Providers im System-Trust-Store (sonst `-SkipCertificateCheck`)

## Dateien

- `Wait-ConfigMgrDeployed.ps1` — Polling-Script, blockiert bis "deployed" oder Timeout
- `main.tf` — Tofu-Beispiel mit `null_resource`

## Aufruf manuell

```bash
pwsh ./Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SmsProvider sccm.corp.local -SiteCode P01
```

Exit-Code 0 = deployed, 1 = Timeout, 2 = Fehler.

## Als Tofu-Modul verwenden

Dieser Ordner ist ein vollständiges Tofu-Modul (`variables.tf`, `main.tf`,
`outputs.tf`). Einbinden:

```hcl
module "wait_for_pc" {
  source                = "../../01-adminservice-pwsh-linux"
  computer_name         = "PC123"
  sms_provider          = "sccm.corp.local"
  site_code             = "P01"
  timeout_seconds       = 7200    # optional, Default 3600
  poll_interval_seconds = 60      # optional, Default 30
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).

## Windows-Variante

Für Windows-Maschinen (PS 5.1, SSPI statt Kerberos) gibt es den eigenständigen
Block [`02-adminservice-pwsh-windows`](../02-adminservice-pwsh-windows/README.md).
Der `windows-pwsh5/`-Unterordner hier bleibt als Referenz erhalten.

## Weitere Demo-Skripte

Im Unterordner [`Demo-pwsh7/`](Demo-pwsh7/) liegen 10 Skripte, die zeigen was
sich noch alles ueber den AdminService abfragen laesst (Devices, Hardware-/
Software-Inventory, Collections, Deployments, Task-Sequence-Status,
Client-Health, Klassen-Discovery, modeled `/v1.0/`-API). Siehe
[`Demo-pwsh7/Übersicht.md`](Demo-pwsh7/Übersicht.md).
