terraform {
  required_version = ">= 1.5"
}

# ===========================================================================
# Stage 1: VM-Provisioning
# ===========================================================================
# Im echten Setup: vsphere_virtual_machine / libvirt_domain / aws_instance /
# proxmox_vm_qemu / azurerm_virtual_machine — was halt eure Plattform ist.
# Hier per null_resource simuliert.

resource "null_resource" "stage1_vm_create" {
  triggers = {
    hostname = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/01-create-vm.sh ${var.computer_name}"

    environment = {
      DRY_RUN = tostring(var.dry_run)
    }
  }
}

# ===========================================================================
# Stage 2: ConfigMgr-Wait
# ===========================================================================
# Wartet, bis die Task-Sequence durch ist und der Client antwortet. Bevor
# Folge-Resources angelegt werden — sonst hat das System z.B. noch keinen
# Hostname, ist nicht in der Domain, hat keinen Monitoring-Agent etc.

module "wait_for_configmgr" {
  source = "../../01-adminservice-pwsh-linux"

  computer_name         = var.computer_name
  sms_provider          = var.sms_provider
  site_code             = var.site_code
  timeout_seconds       = var.configmgr_timeout_seconds
  poll_interval_seconds = var.configmgr_poll_interval_seconds

  depends_on = [null_resource.stage1_vm_create]
}

# ===========================================================================
# Stage 3: Parallele Post-Rollout-Tasks
# ===========================================================================
# Alles was erst Sinn ergibt, wenn die VM in ConfigMgr fertig ist.
# Tofu fuehrt diese drei Resources parallel aus, weil sie nur von Stage 2
# abhaengen, nicht voneinander.

# 3a — DNS-A-Record. Real: cloudflare_record / powerdns_record / etc.
resource "null_resource" "stage3a_dns" {
  triggers = {
    hostname = var.computer_name
    zone     = var.dns_zone
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/03a-add-dns.sh ${var.computer_name} ${var.dns_zone}"

    environment = {
      DRY_RUN = tostring(var.dry_run)
    }
  }

  depends_on = [module.wait_for_configmgr]
}

# 3b — Monitoring-Registrierung. Real: icinga2 / datadog / zabbix / prometheus
resource "null_resource" "stage3b_monitoring" {
  triggers = {
    hostname = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/03b-register-monitoring.sh ${var.computer_name} ${var.monitoring_url}"

    environment = {
      DRY_RUN = tostring(var.dry_run)
    }
  }

  depends_on = [module.wait_for_configmgr]
}

# 3c — CMDB-Eintrag. Real: ServiceNow / iTop / Snipe-IT / Netbox / etc.
resource "null_resource" "stage3c_cmdb" {
  triggers = {
    hostname = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/03c-update-cmdb.sh ${var.computer_name} ${var.cmdb_url}"

    environment = {
      DRY_RUN = tostring(var.dry_run)
    }
  }

  depends_on = [module.wait_for_configmgr]
}

# ===========================================================================
# Stage 4: Final Notification
# ===========================================================================
# Erst wenn ALLE Stage-3-Tasks durch sind. Real: Slack-Webhook / MS Teams /
# E-Mail / PagerDuty.

resource "null_resource" "stage4_notify" {
  triggers = {
    hostname = var.computer_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/04-notify.sh ${var.computer_name} ${var.notify_channel}"

    environment = {
      DRY_RUN = tostring(var.dry_run)
    }
  }

  depends_on = [
    null_resource.stage3a_dns,
    null_resource.stage3b_monitoring,
    null_resource.stage3c_cmdb,
  ]
}
