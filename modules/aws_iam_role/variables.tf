variable "role_name" {
  description = "role_name"
  type        = string
}

variable "principal_type" {
  description = "principal_type"
  type        = string
  default     = null
}

variable "role_version" {
  description = "version"
  type        = string
  default     = null
}

variable "actions" {
  description = "actions"
  type        = list(string)
  default     = null
}

variable "effect" {
  description = "effect"
  type        = string
  default     = null
}

variable "service" {
  description = "Service"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}

variable "custom_assume_role_policy" {
  description = "custom_assume_role_policy"
  type        = string
  default     = ""
}

variable "condition" {
  description = "Опциональный блок Condition для assume_role_policy"
  type        = any
  default     = {}
}

variable "identifiers" {
  description = "List of identifiers for principal"
  type        = list(string)
  default     = []
}
