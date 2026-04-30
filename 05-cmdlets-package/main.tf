variable "computer_name" { type = string }
variable "windows_host"  { type = string }
variable "site_code"     { type = string }
variable "site_server"   { type = string }
variable "cmdlet_path"   {
  type    = string
  default = "C:\\Tools\\PSCMDLets"
}

resource "null_resource" "wait_for_mecm" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      pwsh ${path.module}/Wait-MecmDeployed.ps1 \
        -ComputerName ${var.computer_name} \
        -WindowsHost  ${var.windows_host} \
        -SiteCode     ${var.site_code} \
        -SiteServer   ${var.site_server} \
        -CmdletPath   '${var.cmdlet_path}'
    EOT
  }
}
