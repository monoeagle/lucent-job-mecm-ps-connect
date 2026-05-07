output "id" {
  description = "ID der null_resource — fuer depends_on-Verkettung."
  value       = null_resource.wait_for_configmgr.id
}

output "computer_name" {
  description = "Echo des Computer-Namens."
  value       = var.computer_name
}
