variable "computer_name" { type = string }
variable "sms_provider" { type = string }
variable "site_code"    { type = string }

resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      pwsh ${path.module}/Wait-ConfigMgrDeployed.ps1 \
        -ComputerName ${var.computer_name} \
        -SmsProvider  ${var.sms_provider} \
        -SiteCode     ${var.site_code}
    EOT
  }
}
