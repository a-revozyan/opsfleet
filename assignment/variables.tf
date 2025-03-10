variable "cluster_name" {
  description = "cluster_name"
  type        = string
}

variable "cluster_version" {
  description = "cluster_version"
  type        = string
}

variable "vpc_id" {
  description = "VPC_ID"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "vpc_subnet_ids"
  type        = list(string)
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
