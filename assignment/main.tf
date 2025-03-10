terraform {
  required_version = ">= 1.9.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.89.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks_cluster.aws_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.aws_eks_cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.aws_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.aws_eks_cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        var.cluster_name
      ]
    }
  }
}

#########################
# IAM for EKS Cluster
#########################
module "eks_cluster_iam_role" {
  source         = "../modules/aws_iam_role"
  role_name      = local.eks_cluster_iam_role.role_name
  role_version   = local.eks_cluster_iam_role.role_version
  actions        = local.eks_cluster_iam_role.actions
  effect         = local.eks_cluster_iam_role.effect
  principal_type = local.eks_cluster_iam_role.principal_type
  service        = local.eks_cluster_iam_role.service
  tags           = var.tags
}

module "eks_iam_role_policy_attachment" {
  depends_on  = [module.eks_cluster_iam_role]
  source      = "../modules/aws_iam_role_policy_attachment"
  policy_arns = local.eks_iam_role_policy_attachment.policy_arns
  role_name   = module.eks_cluster_iam_role.aws_iam_role.name
}

# ########################
# IAM for NodeGroup EKS
# ########################
module "eks_node_iam_role" {
  source         = "../modules/aws_iam_role"
  role_name      = local.eks_node_iam_role.role_name
  role_version   = local.eks_node_iam_role.role_version
  actions        = local.eks_node_iam_role.actions
  effect         = local.eks_node_iam_role.effect
  principal_type = local.eks_node_iam_role.principal_type
  service        = local.eks_node_iam_role.service
  tags           = var.tags
}

module "eks_node_iam_role_policy_attachment" {
  depends_on  = [module.eks_node_iam_role]
  source      = "../modules/aws_iam_role_policy_attachment"
  role_name   = module.eks_node_iam_role.aws_iam_role.name
  policy_arns = local.eks_node_iam_role_policy_attachment.policy_arns
}

#########################
# EKS Cluster
#########################
module "eks_cluster" {
  depends_on = [
    module.eks_cluster_iam_role,
    module.eks_node_iam_role
  ]
  source              = "../modules/aws_eks_cluster"
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  authentication_mode = local.eks_cluster.authentication_mode
  cluster_role_arn    = module.eks_cluster_iam_role.aws_iam_role.arn
  vpc_subnet_ids      = var.vpc_subnet_ids
  tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })
}

#########################
# OpenID Connect Provider fors EKS
#########################
module "eks_iam_openid_connect_provider" {
  depends_on      = [module.eks_cluster]
  source          = "../modules/aws_iam_openid_connect_provider"
  main_url        = module.eks_cluster.aws_eks_cluster.identity.0.oidc.0.issuer
  client_id_list  = local.eks_iam_openid_connect_provider.client_id_list
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

#########################
# ADDONS
#########################
module "eks_addons" {
  depends_on   = [module.eks_iam_openid_connect_provider]
  source       = "../modules/aws_eks_addon"
  cluster_name = var.cluster_name
  tags         = var.tags
  addons = {
    "vpc-cni" = local.eks_addons.vpc-cni
  }
}

#########################
# NodeGroup EKS
#########################
module "eks_node_group" {
  depends_on      = [module.eks_cluster]
  source          = "../modules/aws_eks_node_group"
  cluster_name    = module.eks_cluster.aws_eks_cluster.name
  node_group_name = local.eks_node_group.node_group_name
  node_role_arn   = module.eks_node_iam_role.aws_iam_role.arn
  vpc_subnet_ids  = var.vpc_subnet_ids
  desired_size    = local.eks_node_group.desired_size
  max_size        = local.eks_node_group.max_size
  min_size        = local.eks_node_group.min_size
  instance_types  = local.eks_node_group.instance_types
  tags            = var.tags
}

module "node_security_group" {
  depends_on  = [module.eks_cluster]
  source      = "../modules/aws_security_group"
  name        = local.node_security_group.name
  description = local.node_security_group.description
  vpc_id      = var.vpc_id
  ingress = [
    {
      description = local.node_security_group.ingress.description
      from_port   = local.node_security_group.ingress.from_port
      to_port     = local.node_security_group.ingress.to_port
      protocol    = local.node_security_group.ingress.protocol
      cidr_blocks = local.node_security_group.ingress.cidr_blocks
    }
  ]
  egress = [
    {
      description = local.node_security_group.egress.description
      from_port   = local.node_security_group.egress.from_port
      to_port     = local.node_security_group.egress.to_port
      protocol    = local.node_security_group.egress.protocol
      cidr_blocks = local.node_security_group.egress.cidr_blocks
    }
  ]
  tags = { "karpenter.sh/discovery" = var.cluster_name }
}

#########################
# ADDITIONAL ADDONS
#########################
module "eks_addons_additional" {
  depends_on   = [module.eks_node_group]
  source       = "../modules/aws_eks_addon"
  cluster_name = var.cluster_name
  tags         = var.tags
  addons = {
    "kube-proxy"     = local.eks_addons.kube-proxy
    "coredns"        = local.eks_addons.coredns
    "metrics-server" = local.eks_addons.metrics-server
  }
}

#########################
# Access to the Cluster: aws-auth ConfigMap
#########################
module "eks_access_entry_creator" {
  depends_on    = [module.eks_cluster]
  source        = "../modules/aws_eks_access_entry"
  cluster_name  = module.eks_cluster.aws_eks_cluster.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
}

module "eks_access_policy_association" {
  depends_on        = [module.eks_access_entry_creator]
  source            = "../modules/aws_eks_access_policy_association"
  cluster_name      = module.eks_cluster.aws_eks_cluster.name
  principal_arn     = data.aws_iam_session_context.current.issuer_arn
  policy_arn        = local.eks_access_policy_association.policy_arn
  access_scope_type = local.eks_access_policy_association.access_scope_type
}

#########################
# Subnets tagging
#########################
module "karpenter_subnet_tags" {
  depends_on = [module.eks_cluster]
  source     = "../modules/aws_ec2_tag"
  objects    = toset(var.vpc_subnet_ids)
  tag_key    = local.karpenter_subnet_tags.tag_key
  tag_value  = var.cluster_name
}

module "eks_subnet_tags" {
  depends_on = [module.karpenter_subnet_tags]
  source     = "../modules/aws_ec2_tag"
  objects    = toset(var.vpc_subnet_ids)
  tag_key    = "${local.eks_subnet_tags.tag_key}${var.cluster_name}"
  tag_value  = var.cluster_name
}

#########################
# KARPENTER
#########################
module "karpenter" {
  depends_on                      = [module.eks_access_policy_association]
  source                          = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name                    = module.eks_cluster.aws_eks_cluster.name
  create_node_iam_role            = local.karpenter.create_access_entry
  irsa_oidc_provider_arn          = module.eks_iam_openid_connect_provider.aws_iam_openid_connect_provider.arn
  irsa_namespace_service_accounts = local.karpenter.irsa_namespace_service_accounts
  create_access_entry             = local.karpenter.create_access_entry
  tags                            = var.tags
}

resource "null_resource" "update_karpenter_trust" {
  depends_on = [module.karpenter]
  triggers = {
    role_arn = module.karpenter.iam_role_arn
    oidc_arn = module.eks_iam_openid_connect_provider.aws_iam_openid_connect_provider.arn
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = { AWS_REGION = "us-east-1" }
    command     = <<-EOT
      aws iam update-assume-role-policy --role-name ${split("/", module.karpenter.iam_role_arn)[1]} --policy-document '${local.karpenter_trust_policy}'
    EOT
  }
}

module "iam_inline_policies" {
  source    = "../modules/aws_iam_role_policy"
  role_name = module.karpenter.iam_role_name
  inline_policies = {
    "PassRolePolicy"                = jsonencode(local.pass_role_policy)
    "CreateServiceLinkedRolePolicy" = jsonencode(local.create_service_linked_role_policy)
    "EC2ActionsPolicy"              = jsonencode(local.ec2_actions_policy)
  }
}

########################
# HELM - KARPENTER
########################
resource "helm_release" "karpenter_crd" {
  depends_on       = [module.karpenter]
  namespace        = local.karpenter_crd.namespace
  create_namespace = true
  name             = local.karpenter_crd.name
  repository       = local.karpenter_crd.repository
  chart            = local.karpenter_crd.chart
  version          = local.karpenter_crd.chart_version
  replace          = true
  force_update     = true
}

resource "helm_release" "karpenter" {
  depends_on       = [helm_release.karpenter_crd]
  namespace        = local.karpenter_release.namespace
  create_namespace = true
  name             = local.karpenter_release.name
  repository       = local.karpenter_release.repository
  chart            = local.karpenter_release.chart
  version          = local.karpenter_release.chart_version
  replace          = true
  set {
    name  = "serviceMonitor.enabled"
    value = false
  }
  set {
    name  = "settings.clusterName"
    value = module.eks_cluster.aws_eks_cluster.name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = module.eks_cluster.aws_eks_cluster.endpoint
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }
  set {
    name  = "settings.interruptionQueueName"
    value = module.karpenter.queue_name
  }
  set {
    name  = "settings.featureGates.drift"
    value = true
  }
}
