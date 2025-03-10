data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "tls_certificate" "eks_oidc" {
  url = module.eks_cluster.aws_eks_cluster.identity.0.oidc.0.issuer
}

data "aws_security_groups" "eks_nodegroup_sg" {
  filter {
    name   = "tag:aws:eks:nodegroup"
    values = [module.eks_node_group.aws_eks_node_group.node_group_name]
  }

  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [var.cluster_name]
  }
}
