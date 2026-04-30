variable "computer_name" { type = string }
variable "jumphost"      { type = string }
variable "site_code"     { type = string }

resource "null_resource" "wait_for_mecm" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      pwsh ${path.module}/Wait-MecmDeployed.ps1 \
        -ComputerName ${var.computer_name} \
        -Jumphost     ${var.jumphost} \
        -SiteCode     ${var.site_code}
    EOT
  }
}
