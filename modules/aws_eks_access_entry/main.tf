resource "aws_eks_access_entry" "this" {
  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  tags          = var.tags
}
