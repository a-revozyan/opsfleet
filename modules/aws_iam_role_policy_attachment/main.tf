# resource "aws_iam_role_policy_attachment" "this" {
#   for_each   = toset(var.policy_arns)
#   policy_arn = each.value
#   role       = var.role_name
# }

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = { for idx, arn in var.policy_arns : idx => arn }
  policy_arn = each.value
  role       = var.role_name
}
