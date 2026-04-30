terraform {
  required_version = ">= 1.5"
}

# Beispiel: warten bis ein Rechner in ConfigMgr ausgerollt ist, dann
# Folge-Resources darauf aufsetzen.
#
# Tausche `source` und Variablen je nach gewaehltem Weg (siehe README.md).

module "wait_for_pc" {
  source = "../../01-adminservice-pwsh"

  computer_name         = "PC123"
  sms_provider          = "sccm.corp.local"
  site_code             = "P01"
  timeout_seconds       = 7200
  poll_interval_seconds = 60

  # Nur in Test-Umgebungen ohne CA-Trust:
  # skip_certificate_check = true
}

# Beispiel-Folge-Resource — wartet implizit ueber depends_on auf das Modul.
resource "null_resource" "after_rollout" {
  depends_on = [module.wait_for_pc]

  provisioner "local-exec" {
    command = "echo 'PC123 ist deployed — hier koennten weitere Steps laufen.'"
  }
}

output "deployed_pc" {
  description = "Ausgerollter Rechner."
  value       = module.wait_for_pc.computer_name
}
