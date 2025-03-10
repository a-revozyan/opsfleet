variable "cluster_name" {
  description = "cluster_name"
  type        = string
}

variable "node_group_name" {
  description = "node_group_name"
  type        = string
}

variable "node_role_arn" {
  description = "node_role_arn"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "vpc_subnet_ids"
  type        = list(string)
}

variable "instance_types" {
  description = "instance_types"
  type        = list(string)
}

variable "desired_size" {
  description = "desired_size"
  type        = number
}

variable "max_size" {
  description = "max_size"
  type        = number
}

variable "min_size" {
  description = "min_size"
  type        = number
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
