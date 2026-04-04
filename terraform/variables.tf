variable "subscription_id" {
  description = "Azure subscription ID. Passed via environment variable TF_VAR_subscription_id — never hardcoded."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID. Passed via environment variable TF_VAR_tenant_id — never hardcoded."
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "canadaeast"
}

variable "environment" {
  description = "Deployment environment (prod, staging, dev)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name used in tagging and naming."
  type        = string
  default     = "sentinel-claude-soc"
}
