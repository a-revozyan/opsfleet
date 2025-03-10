variable "policy_name" {
  type        = string
  description = "Name of the policy"
}

variable "policy_description" {
  type        = string
  description = "Description of the policy"
}

variable "policy_json" {
  description = "IAM policy document in JSON format"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
