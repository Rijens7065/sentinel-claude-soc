variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

variable "law_retention_days" {
  description = "Log Analytics Workspace retention in days."
  type        = number
  default     = 30
}
