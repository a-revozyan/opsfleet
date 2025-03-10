variable "role_name" {
  description = "role_name"
  type        = string
}

variable "inline_policies" {
  description = "inline_policies"
  type        = map(string)
}
