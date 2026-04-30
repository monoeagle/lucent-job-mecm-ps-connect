output "hostname" {
  description = "Ausgerollter Hostname."
  value       = var.computer_name
}

output "fqdn" {
  description = "Voller DNS-Name (hostname + zone)."
  value       = "${var.computer_name}.${var.dns_zone}"
}

output "rollout_complete_id" {
  description = "ID der finalen Notify-Resource. Downstream-Stacks koennen ueber depends_on darauf warten."
  value       = null_resource.stage4_notify.id
}
