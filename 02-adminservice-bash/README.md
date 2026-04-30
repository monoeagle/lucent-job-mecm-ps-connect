# 02 — AdminService via Bash + curl

Wie 01, aber ohne PowerShell-Dependency. Pure Bash, `curl` mit Kerberos und `jq`.

## Voraussetzungen

- `curl` mit GSS-Negotiate-Support (`curl --negotiate`)
- `jq`
- `krb5-user` (für `kinit`)
- AdminService erreichbar, CA im Trust-Store

## Dateien

- `wait-configmgr-deployed.sh`
- `main.tf`

## Aufruf manuell

```bash
kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL
./wait-configmgr-deployed.sh PC123 sccm.corp.local P01
```
