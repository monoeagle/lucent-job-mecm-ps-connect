resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/wait-configmgr-deployed.sh ${var.computer_name} ${var.sms_provider} ${var.site_code}"

    environment = {
      TIMEOUT_SECONDS       = tostring(var.timeout_seconds)
      POLL_INTERVAL_SECONDS = tostring(var.poll_interval_seconds)
    }
  }
}
