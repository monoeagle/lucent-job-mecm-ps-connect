variable "computer_name" { type = string }
variable "sms_provider" { type = string }
variable "site_code"    { type = string }

resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/wait-configmgr-deployed.sh ${var.computer_name} ${var.sms_provider} ${var.site_code}"
  }
}
