variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "addons" {
  description = "Map of EKS addons to install (name = version)"
  type        = map(string)
}

variable "service_account_roles" {
  description = "Map of addon names to their IAM role ARNs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
