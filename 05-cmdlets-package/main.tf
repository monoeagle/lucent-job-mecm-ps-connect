resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      pwsh ${path.module}/Wait-ConfigMgrDeployed.ps1 \
        -ComputerName         '${var.computer_name}' \
        -WindowsHost          '${var.windows_host}' \
        -SiteCode             '${var.site_code}' \
        -SiteServer           '${var.site_server}' \
        -CmdletPath           '${var.cmdlet_path}' \
        -TimeoutSeconds       ${var.timeout_seconds} \
        -PollIntervalSeconds  ${var.poll_interval_seconds}
    EOT
  }
}
