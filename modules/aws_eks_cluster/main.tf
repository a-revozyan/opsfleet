resource "aws_eks_cluster" "this" {
  name = var.cluster_name

  access_config {
    authentication_mode = var.authentication_mode
  }

  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

  compute_config {
    enabled = var.compute_config_enabled
    # node_pools    = var.node_pools
    # node_role_arn = var.node_role_arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = var.elastic_load_balancing_enabled
    }
  }

  storage_config {
    block_storage {
      enabled = var.block_storage_enabled
    }
  }

  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.vpc_subnet_ids
  }
  tags = var.tags
}
