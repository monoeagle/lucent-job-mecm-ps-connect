variable "computer_name" {
  description = "ConfigMgr Resource.Name (= Hostname) auf den gewartet wird."
  type        = string
}

variable "sql_host" {
  description = "FQDN des ConfigMgr-SQL-Servers."
  type        = string
}

variable "db_name" {
  description = "ConfigMgr-Datenbankname (z.B. CM_P01)."
  type        = string

  validation {
    condition     = can(regex("^CM_[A-Z0-9]{3}$", var.db_name))
    error_message = "db_name muss dem Schema CM_<3-Zeichen-SiteCode> folgen, z.B. CM_P01."
  }
}

variable "timeout_seconds" {
  description = "Maximale Wartezeit. Default 3600."
  type        = number
  default     = 3600

  validation {
    condition     = var.timeout_seconds > 0 && var.timeout_seconds <= 86400
    error_message = "timeout_seconds muss zwischen 1 und 86400 liegen."
  }
}

variable "poll_interval_seconds" {
  description = "Polling-Intervall."
  type        = number
  default     = 30

  validation {
    condition     = var.poll_interval_seconds >= 5 && var.poll_interval_seconds <= 600
    error_message = "poll_interval_seconds muss zwischen 5 und 600 liegen."
  }
}

variable "sql_user" {
  description = "Optional: SQL-User fuer SQL-Auth. Wenn leer, wird Windows Integrated Auth (SSPI) verwendet."
  type        = string
  default     = ""
}

variable "sql_password" {
  description = "Optional: SQL-Passwort. Nur in Kombination mit sql_user. Sollte aus Secret-Backend kommen."
  type        = string
  default     = ""
  sensitive   = true
}
