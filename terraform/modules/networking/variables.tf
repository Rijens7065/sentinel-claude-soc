variable "resource_group_name" {
  description = "Name of the resource group to deploy networking into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_functions_prefix" {
  description = "Address prefix for the Functions subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private_endpoints_prefix" {
  description = "Address prefix for the Private Endpoints subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_reserved_prefix" {
  description = "Address prefix for the Reserved subnet."
  type        = string
  default     = "10.0.3.0/24"
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
