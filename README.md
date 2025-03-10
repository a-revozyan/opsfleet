# Task Description

**You've joined a new and growing startup.**

The company wants to build its initial Kubernetes infrastructure on AWS. The team wants to leverage the latest autoscaling capabilities by Karpenter, as well as utilize Graviton and Spot instances for better price/performance.

They have asked you if you can help create the following:

Terraform code that deploys an EKS cluster (whatever latest version is currently available) into an existing VPC

The terraform code should also deploy Karpenter with node pool(s) that can deploy both x86 and arm64 instances

Include a short readme that explains how to use the Terraform repo and that also demonstrates how an end-user (a developer from the company) can run a pod/deployment on x86 or Graviton instance inside the cluster.

# Project Overview

This project deploys an EKS cluster with a managed node group and two custom IAM roles – one for the EKS cluster and one for the EKS node group using on-demand instances. In addition to that the project deploys Karpenter, Karpenter NodePool and EC2NodeClass. The following components are provisioned:

- **Addons:**  
  - CoreDNS  
  - Kube-proxy  
  - VPC-CNI  
  - Metrics-server

- **Security Group:**  
  A security group is created with the required tag.

- **Karpenter Module:**  
  Deploys Karpenter, which creates:
  - IAM roles  
  - SQS queues  
  - CloudWatch Event Rules and Targets

- **Helm Deployment:**  
  Karpenter CRD and the Karpenter controller are deployed via Helm.

- **Final Step – Karpenter Node Group and EC2NodeClass:**  
  - **NodePool "spot":** Defines a node pool with specific requirements (architecture, OS, spot capacity type, instance category, and generation), a CPU limit, an expiration time of 720 hours, and a consolidation policy.  
  - **EC2NodeClass "default":** Specifies the parameters for creating EC2 instances for the node pool, including the IAM role (provided by the `KARPENTER_ROLE` variable), the AMI selection via alias, and selectors for subnets and security groups based on the cluster tag (`CLUSTER_NAME`).

In the repository root, there is a test Kubernetes manifes `test-deployment.yaml` that can be applied to observe how a worker node is created.

---

## Prerequisites

You can deploy this project in your custom VPC (make sure your VPC has correctly configured private and public subnets, routes, NAT gateways, etc.). For simplicity, you may also use the default VPC provided by AWS.

# Recommendations
1. EKS version - 1.32
2. AWS region - us-east-1 (you can use another AWS region, be sure that all of the AWS regions AZs can work  with EKS)

# Versions
Addons
1. vpc-cni        = "v1.19.2-eksbuild.1"
2. kube-proxy     = "v1.32.0-eksbuild.2,
3. coredns        = "v1.11.4-eksbuild.2",
4. metrics-server = "v0.7.2-eksbuild.1
5. Karpenter      = "1.3.1"

# Accessibility
1. EKS ControlPlane is accessible through public address. It should be external because of avoiding VPN 

To automatically deploy the project, run the `main-script.sh` script:

1. **Make the script executable and run it:**
   ```bash
   chmod +x ./main-script.sh
   source main-script.sh
The script performs the following steps:

1. **Check and Install Terraform**
2. **Check and Install kubectl**
3. **Check and Install Helm**
4. **Check and Install AWS CLI**
5. **Prompt for AWS Credentials:**  
   You will be asked to provide your `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, as well as the Kubernetes cluster name and version, and a tag key/value (e.g., key: `environment`, value: `development`).
6. **Provide VPC ID:**  
   All subnets within the provided VPC will be automatically gathered.
7. **Change directory to the Terraform stage**
8. **Run `terraform init` and `terraform plan`:**  
   You can review the output.
9. **Run `terraform apply`:**  
   Confirm the deployment by typing `y` when prompted.
10. **Configure kubectl access.**
11. **Deploy Karpenter NodePool and EC2NodeClass.**
12. **Save the provided data:**  
    A corresponding `destroy-script.sh` will use the same values to run `terraform destroy` for resource cleanup.
    You should delete all your deployment/pods before running `destroy-script.sh`.

**Example values for deployment and destruction scripts:**

- `AWS_ACCESS_KEY_ID` - `AKIAX************`
- `AWS_SECRET_ACCESS_KEY` - `0+Vg*******************************`
- `AWS_DEFAULT_REGION` - `us-east-1`
- `KUBERNETES_CLUSTER_NAME` - `main_eks_cluster`
- `KUBERNETES_VERSION` - `1.32`
- `TAG_KEY` - `environment`
- `TAG_VALUE` - `development`
- `VPC_ID` - `vpc-08dbc022f03e4db9b`
