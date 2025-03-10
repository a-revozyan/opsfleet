variable "name" {
  description = "Security Group name"
  type        = string
}

variable "description" {
  description = "Security Group description"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID VPC"
  type        = string
}

variable "ingress" {
  description = "List of ingress rules"
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
  }))
  default = []
}

variable "egress" {
  description = "List egress rules"
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
  }))
  default = []
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
