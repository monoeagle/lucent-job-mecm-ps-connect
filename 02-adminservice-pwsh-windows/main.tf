resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NonInteractive", "-NoProfile", "-Command"]
    command     = <<-EOT
      & '${path.module}\Wait-ConfigMgrDeployed.ps1' `
        -ComputerName        '${var.computer_name}' `
        -SmsProvider         '${var.sms_provider}' `
        -SiteCode            '${var.site_code}' `
        -TimeoutSeconds       ${var.timeout_seconds} `
        -PollIntervalSeconds  ${var.poll_interval_seconds} `
        ${var.skip_certificate_check ? "-SkipCertificateCheck" : ""}
    EOT
  }
}
