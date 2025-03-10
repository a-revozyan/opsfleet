resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies
  name     = each.key
  role     = var.role_name
  policy   = each.value
}
