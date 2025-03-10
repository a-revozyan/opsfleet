resource "aws_iam_instance_profile" "this" {
  name = var.instsance_profile_name
  role = var.role_name
  tags = var.tags
}
