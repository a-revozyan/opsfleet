variable "objects" {
  description = "objects to tag"
  type        = set(string)
}

variable "tag_key" {
  description = "tag_key"
  type        = string
}

variable "tag_value" {
  description = "tag_value"
  type        = string
}
