variable "computer_name" { type = string }
variable "sql_host"      { type = string }
variable "db_name"       { type = string }   # z.B. CM_P01

resource "null_resource" "wait_for_mecm" {
  triggers = {
    computer_name = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/wait-mecm-deployed.sh ${var.computer_name} ${var.sql_host} ${var.db_name}"
  }
}
