# 01 — AdminService via PowerShell 7

Linux-Runner ruft die AdminService REST API von ConfigMgr direkt mit `Invoke-RestMethod` auf.

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
