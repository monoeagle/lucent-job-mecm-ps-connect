variable "computer_name" {
  description = "ConfigMgr Resource.Name (= Hostname) auf den gewartet wird."
  type        = string
}

variable "windows_host" {
  description = "FQDN des Windows-Hosts, auf dem das Cmdlet-Package liegt und WinRM HTTPS angeboten wird."
  type        = string
}

variable "site_code" {
  description = "ConfigMgr-SiteCode (3 Zeichen)."
  type        = string

  validation {
    condition     = length(var.site_code) == 3
    error_message = "site_code muss exakt 3 Zeichen lang sein."
  }
}

variable "site_server" {
  description = "FQDN des ConfigMgr-Site-Servers (Root fuer New-PSDrive CMSite)."
  type        = string
}

variable "cmdlet_path" {
  description = "Windows-Pfad zum entpackten Cmdlet-Package."
  type        = string
  default     = "C:\\Tools\\PSCMDLets"
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
