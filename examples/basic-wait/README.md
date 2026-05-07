# Beispiel — basic-wait

Minimaler Stack, der zeigt wie man eine der sieben Modul-Varianten in
einem realen Tofu-Projekt einsetzt.

## Was das Beispiel tut

1. Wartet ueber das Modul `01-adminservice-pwsh-linux`, bis `PC123` in
   ConfigMgr den Status "ausgerollt" hat (Task-Sequence Success + Client aktiv).
2. Triggert eine Folge-Resource (`null_resource.after_rollout`), die
   implizit ueber `depends_on` haengt — Tofu fuehrt sie erst aus, wenn
   das Wait-Modul erfolgreich fertig ist.
3. Exportiert den Computer-Namen als Output.

## Verwenden

```bash
cd examples/basic-wait
tofu init
tofu apply
```

Voraussetzungen: siehe [`docs/auth-setup.md`](../../docs/auth-setup.md).

## Variante wechseln

Ersetze den `module`-Block in `main.tf` durch eine andere Quelle und
passe die Variablen an.

### Variante 02 — AdminService + PS 5.1 (Windows)
```hcl
module "wait_for_pc" {
  source        = "../../02-adminservice-pwsh-windows"
  computer_name = "PC123"
  sms_provider  = "sccm.corp.local"
  site_code     = "P01"
}
```

### Variante 03 — AdminService + bash/curl (Linux)
```hcl
module "wait_for_pc" {
  source        = "../../03-adminservice-bash-linux"
  computer_name = "PC123"
  sms_provider  = "sccm.corp.local"
  site_code     = "P01"
}
```

### Variante 04 — WinRM-Jumphost mit Console
```hcl
module "wait_for_pc" {
  source        = "../../04-winrm-jumphost"
  computer_name = "PC123"
  jumphost      = "cmjump01.corp.local"
  site_code     = "P01"
}
```

### Variante 05 — SQL direkt (Linux)
```hcl
module "wait_for_pc" {
  source        = "../../05-sql-direct-linux"
  computer_name = "PC123"
  sql_host      = "sql.corp.local"
  db_name       = "CM_P01"

  # Optional Username/Passwort-Auth statt Kerberos:
  # sql_user     = "tofu_reader"
  # sql_password = var.sql_password   # aus Secret-Backend
}
```

### Variante 06 — SQL direkt + PS 5.1 (Windows)
```hcl
module "wait_for_pc" {
  source        = "../../06-sql-direct-windows"
  computer_name = "PC123"
  sql_host      = "sql.corp.local"
  db_name       = "CM_P01"
}
```

### Variante 07 — WinRM + Cmdlet-Package
```hcl
module "wait_for_pc" {
  source        = "../../07-cmdlets-package"
  computer_name = "PC123"
  windows_host  = "cmworker01.corp.local"
  site_code     = "P01"
  site_server   = "sccm.corp.local"
}
```

## Folge-Resources

Alle Module exportieren `id` und `computer_name`. Folge-Resources
haengen sich am sauberesten ueber `depends_on = [module.wait_for_pc]`
an — das laesst Tofu den Wait erst abschliessen, bevor die naechste
Resource startet.
