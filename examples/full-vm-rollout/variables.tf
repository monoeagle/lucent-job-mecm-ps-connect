variable "computer_name" {
  description = "Hostname der neuen VM (= ConfigMgr Resource.Name)."
  type        = string
}

variable "sms_provider" {
  description = "FQDN des ConfigMgr SMS-Providers."
  type        = string
}

variable "site_code" {
  description = "ConfigMgr-SiteCode."
  type        = string
}

variable "configmgr_timeout_seconds" {
  description = "Timeout fuer das ConfigMgr-Wait (Stage 2). Default 2h."
  type        = number
  default     = 7200
}

variable "configmgr_poll_interval_seconds" {
  description = "Polling-Intervall fuer das ConfigMgr-Wait."
  type        = number
  default     = 30
}

variable "dns_zone" {
  description = "DNS-Zone, in der das A-Record angelegt wird."
  type        = string
  default     = "corp.local"
}

variable "monitoring_url" {
  description = "Endpoint des Monitoring-Systems (Icinga / Datadog / etc.)."
  type        = string
  default     = "https://monitoring.corp.local/api/v1/hosts"
}

variable "cmdb_url" {
  description = "Endpoint der CMDB."
  type        = string
  default     = "https://cmdb.corp.local/api/v2/devices"
}

variable "notify_channel" {
  description = "Notification-Ziel (Slack-Channel, MS-Teams-Webhook-ID, etc.)."
  type        = string
  default     = "#ops-rollout"
}

variable "dry_run" {
  description = "Wenn true: alle Stage-Skripte loggen nur, ohne tatsaechliche API-Calls. Default true (Demo-Modus)."
  type        = bool
  default     = true
}
