resource "null_resource" "wait_for_configmgr" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NonInteractive", "-NoProfile", "-Command"]
    command     = <<-EOT
      & '${path.module}\Wait-ConfigMgrDeployed.ps1' `
        -ComputerName        '${var.computer_name}' `
        -SqlHost             '${var.sql_host}' `
        -DbName              '${var.db_name}' `
        -TimeoutSeconds       ${var.timeout_seconds} `
        -PollIntervalSeconds  ${var.poll_interval_seconds} `
        ${var.sql_user != "" ? "-SqlUser '${var.sql_user}' -SqlPassword '${var.sql_password}'" : ""}
    EOT
  }
}
