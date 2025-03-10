variable "cluster_name" {
  description = "cluster_name"
  type        = string
}

variable "principal_arn" {
  description = "principal_arn"
  type        = string
}

variable "policy_arn" {
  description = "policy_arn"
  type        = string
}

variable "access_scope_type" {
  description = "access_scope_type"
  type        = string
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
