variable "cluster_name" {
  description = "cluster_name"
  type        = string
}

variable "cluster_version" {
  description = "cluster_version"
  type        = string
}

variable "authentication_mode" {
  description = "authentication_mode"
  type        = string
}

variable "cluster_role_arn" {
  description = "cluster_role_arn"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "vpc_subnet_ids"
  type        = list(string)
}

variable "bootstrap_self_managed_addons" {
  description = "bootstrap_self_managed_addons"
  type        = bool
  default     = false
}

variable "elastic_load_balancing_enabled" {
  description = "elastic_load_balancing_enabled"
  type        = bool
  default     = false
}

variable "block_storage_enabled" {
  description = "block_storage_enabled"
  type        = bool
  default     = false
}

variable "compute_config_enabled" {
  description = "compute_config_enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
