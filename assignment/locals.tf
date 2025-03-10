locals {
  ########################
  # IAM for EKS Cluster
  ########################
  eks_cluster_iam_role = {
    role_name      = "eks-cluster-iam-role",
    role_version   = "2012-10-17",
    actions        = ["sts:AssumeRole"],
    effect         = "Allow",
    principal_type = "Service",
    service        = "eks.amazonaws.com"
  }
  eks_iam_role_policy_attachment = {
    policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
  }

  #########################
  # IAM for CODEDNS of EKS
  #########################
  eks_core_dns_iam_role = {
    role_name      = "eks-core-dns-role",
    role_version   = "2012-10-17",
    actions        = ["sts:AssumeRoleWithWebIdentity"],
    effect         = "Allow",
    principal_type = "Federated",
    identifiers    = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${split("/", data.aws_caller_identity.current.arn)[1]}"]
  }
  eks_core_dns_iam_role_policy = {
    policy_name        = "eks-core-dns-policy",
    policy_description = "Policy for EKS CoreDNS",
    policy_version     = "2012-10-17",
    policy_effect      = "Allow",
    policy_action = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets"
    ],
    policy_resource = "*",
  }

  #########################
  # EKS Cluster
  #########################
  eks_cluster = {
    authentication_mode            = "API_AND_CONFIG_MAP",
    elastic_load_balancing_enabled = true,
    block_storage_enabled          = true
    public_access                  = false
    private_access                 = true
  }

  #########################
  # NodeGroup EKS
  #########################
  eks_node_group = {
    node_group_name = "workers",
    desired_size    = 2,
    max_size        = 3,
    min_size        = 2,
    instance_types  = ["t3.medium"]
  }

  #########################
  # NODE SECURITY GROUP
  #########################
  node_security_group = {
    name        = "eks-node-security-group"
    description = "EKS Node Security Group"
    ingress = {
      description = "Allow all traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress = {
      description = "Allow all traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  #########################
  # OpenID Connect Provider fors EKS
  #########################
  eks_iam_openid_connect_provider = {
    client_id_list = ["sts.amazonaws.com"]
  }

  #########################
  # KARPENTER
  #########################
  karpenter = {
    create_node_iam_role            = true,
    create_access_entry             = true,
    irsa_namespace_service_accounts = ["karpenter:karpenter"]
  }

  #########################
  # HELM - KARPENTER
  #########################
  karpenter_crd = {
    namespace     = "karpenter",
    chart         = "karpenter-crd",
    name          = "karpenter-crd",
    chart_version = "1.3.1"
    repository    = "oci://public.ecr.aws/karpenter"
  }

  karpenter_release = {
    namespace     = "karpenter",
    chart         = "karpenter",
    name          = "karpenter",
    chart_version = "1.3.1"
    repository    = "oci://public.ecr.aws/karpenter"
  }
  #########################
  # INLINE POLICIES
  #########################
  pass_role_policy = {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : module.karpenter.iam_role_arn
      }
    ]
  }

  create_service_linked_role_policy = {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "spot.amazonaws.com"
          }
        }
      }
    ]
  }

  ec2_actions_policy = {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeSpotInstanceRequests",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateLaunchTemplate"
        ],
        "Resource" : "*"
      }
    ]
  }

  #########################
  # ADDONS
  #########################
  eks_addons = {
    vpc-cni        = "v1.19.2-eksbuild.1",
    kube-proxy     = "v1.32.0-eksbuild.2",
    coredns        = "v1.11.4-eksbuild.2",
    metrics-server = "v0.7.2-eksbuild.1"
  }

  #########################
  # Access to the Cluster: aws-auth ConfigMap
  #########################
  eks_access_policy_association = {
    policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
    access_scope_type = "cluster"
  }
  eks_node_iam_role = {
    role_name      = "eks-node-group-role",
    role_version   = "2012-10-17",
    actions        = ["sts:AssumeRole"],
    effect         = "Allow",
    principal_type = "Service",
    service        = "ec2.amazonaws.com"
  }
  eks_node_iam_role_policy_attachment = {
    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ]
  }

  #########################
  # Instance Profile for Karpenter
  #########################
  karpenter_instsance_profile = {
    instsance_profile_name = "karpenter-instance-profile"
  }

  #########################
  # Instance Profile for Karpenter
  #########################
  karpenter_subnet_tags = {
    tag_key = "karpenter.sh/discovery"
  }
  eks_subnet_tags = {
    tag_key = "kubernetes.io/cluster/"
  }
  karpenter_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Statement для Web Identity
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks_iam_openid_connect_provider.aws_iam_openid_connect_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks_iam_openid_connect_provider.aws_iam_openid_connect_provider.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      },

      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}
