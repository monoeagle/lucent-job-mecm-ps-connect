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

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source        = "../../02-adminservice-bash"
  computer_name = "PC123"
  sms_provider  = "sccm.corp.local"
  site_code     = "P01"
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).

## Weitere Demo-Skripte

Im Unterordner [`Demo/`](Demo/) liegen 10 Skripte, die zeigen was sich noch
alles ueber den AdminService abfragen laesst (Devices, Hardware-/Software-
Inventory, Collections, Deployments, Task-Sequence-Status, Client-Health,
Klassen-Discovery, modeled `/v1.0/`-API). Siehe
[`Demo/Übersicht.md`](Demo/Übersicht.md).
