resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = var.client_id_list
  url             = var.main_url
  thumbprint_list = var.thumbprint_list
  tags            = var.tags
}
