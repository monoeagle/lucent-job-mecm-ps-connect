variable "computer_name" {
  description = "ConfigMgr Resource.Name (= Hostname) auf den gewartet wird."
  type        = string
}

variable "sms_provider" {
  description = "FQDN des SMS-Providers, der den AdminService hostet (z.B. sccm.corp.local)."
  type        = string
}

variable "site_code" {
  description = "ConfigMgr-SiteCode (3 Zeichen, z.B. P01)."
  type        = string

  validation {
    condition     = length(var.site_code) == 3
    error_message = "site_code muss exakt 3 Zeichen lang sein."
  }
}

variable "timeout_seconds" {
  description = "Maximale Wartezeit, bevor das Modul fehlschlaegt. Default 3600 = 1h."
  type        = number
  default     = 3600

  validation {
    condition     = var.timeout_seconds > 0 && var.timeout_seconds <= 86400
    error_message = "timeout_seconds muss zwischen 1 und 86400 (24h) liegen."
  }
}

variable "poll_interval_seconds" {
  description = "Wartezeit zwischen zwei AdminService-Abfragen."
  type        = number
  default     = 30

  validation {
    condition     = var.poll_interval_seconds >= 5 && var.poll_interval_seconds <= 600
    error_message = "poll_interval_seconds muss zwischen 5 und 600 liegen."
  }
}

variable "skip_certificate_check" {
  description = "TLS-Zertifikat-Validierung ueberspringen. NUR fuer Test-Umgebungen ohne CA-Trust."
  type        = bool
  default     = false
}
