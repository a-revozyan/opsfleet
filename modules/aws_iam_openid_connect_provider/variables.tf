variable "main_url" {
  description = "main_url"
  type        = string
}

variable "client_id_list" {
  description = "client_id_list"
  type        = list(string)
}

variable "thumbprint_list" {
  description = "thumbprint_list"
  type        = list(string)
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}
