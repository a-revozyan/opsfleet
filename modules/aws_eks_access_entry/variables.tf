variable "cluster_name" {
  description = "cluster_name"
  type        = string
}

variable "principal_arn" {
  description = "principal_arn"
  type        = string
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
