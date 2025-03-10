resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name  = var.cluster_name
  addon_name    = each.key
  addon_version = each.value
  tags          = var.tags

  service_account_role_arn = lookup(var.service_account_roles, each.key, null)
}
