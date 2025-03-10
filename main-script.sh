#!/bin/bash
set -e

##############################
# Step 1: Check and Install Terraform
##############################
echo "Step 1: Checking if Terraform is installed"
if command -v terraform >/dev/null 2>&1; then
  echo "Terraform is already installed:"
  terraform --version
  echo "Proceeding with further checks and steps"
  echo ""
else
  echo "Terraform is not installed. Proceeding with installation"

  # Determine OS type
  OS_TYPE=$(uname -s)
  if [ "$OS_TYPE" = "Darwin" ]; then
    OS_ID="darwin"
  else
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID=$ID
    else
      echo "Unable to determine the OS type"
      exit 1
    fi
  fi

  echo "Detected OS: $OS_TYPE ($OS_ID)"

  # Install Terraform based on OS
  case "$OS_ID" in
    debian|ubuntu)
      echo "Installing Terraform on Debian/Ubuntu"
      wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
      sudo apt update && sudo apt install -y terraform
      ;;
    rhel|centos|fedora|almalinux)
      echo "Installing Terraform on RHEL/CentOS/Fedora/AlmaLinux"
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      sudo yum -y install terraform
      ;;
    darwin)
      echo "Installing Terraform on macOS"
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Please install Homebrew from https://brew.sh and rerun this script."
        exit 1
      fi
      brew tap hashicorp/tap
      brew install hashicorp/tap/terraform
      ;;
    *)
      echo "Unsupported OS. Please install Terraform manually."
      exit 1
      ;;
  esac

  echo "Terraform installation complete. Installed version:"
  terraform --version
  echo ""
fi

##############################
# Step 2: Check and Install kubectl
##############################
echo "Step 2: Checking if kubectl is installed"
if command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is already installed:"
  kubectl version --client
  echo ""
else
  echo "kubectl is not installed. Proceeding with installation"
  # Automatic installation is configured for Linux systems only
  if [ "$(uname -s)" != "Linux" ]; then
    echo "Automatic installation for kubectl is only configured for Linux. Please install kubectl manually for your OS."
  else
    KUBECTL_URL="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "Downloading kubectl from $KUBECTL_URL"
    curl -LO "$KUBECTL_URL"
    echo "Installing kubectl to /usr/local/bin"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
  fi
  echo "kubectl installation complete. Installed version:"
  kubectl version --client
  echo ""
fi

##############################
# Step 3: Check and Install Helm
##############################
echo "Step 3: Checking if helm is installed"
if command -v helm >/dev/null 2>&1; then
  echo "Helm is already installed:"
  helm version --short
  echo ""
else
  echo "Helm is not installed. Proceeding with installation"
  curl -fsSL -o get-helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get-helm.sh
  ./get-helm.sh
  rm get-helm.sh
  echo "Helm installation complete. Installed version:"
  helm version --short
  echo ""
fi

##############################
# Step 4: Check and Install AWS CLI
##############################
echo "Step 4: Checking if AWS CLI is installed"
if command -v aws >/dev/null 2>&1; then
  echo "AWS CLI is already installed:"
  aws --version
  echo ""
else
  echo "AWS CLI is not installed. Proceeding with installation"
  OS_TYPE=$(uname -s)
  if [ "$OS_TYPE" = "Darwin" ]; then
    echo "Installing AWS CLI on macOS"
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
    rm AWSCLIV2.pkg
  else
    # For Linux: determine distribution to choose package manager
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID=$ID
    else
      echo "Unable to determine the Linux distribution"
      exit 1
    fi

    if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
      echo "Installing AWS CLI on Debian/Ubuntu"
      sudo apt install -y unzip
    elif [ "$OS_ID" = "rhel" ] || [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "fedora" ] || [ "$OS_ID" = "almalinux" ]; then
      echo "Installing AWS CLI on RHEL/CentOS/Fedora/AlmaLinux"
      sudo yum install -y unzip
    else
      echo "Unsupported Linux distribution. Please install AWS CLI manually."
      exit 1
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
  fi
  echo "AWS CLI installation complete. Installed version:"
  aws --version
  echo ""
fi

##############################
# Step 5: Prompt for AWS Credentials
##############################
echo "Step 5: Enter AWS credentials"
read -p "Enter AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -p "Enter AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "Enter AWS_DEFAULT_REGION: " AWS_DEFAULT_REGION
echo ""

# Export the credentials as environment variables for subsequent Terraform operations
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

echo "AWS credentials have been set."
echo ""

##############################
# Step 6: Prompt for Cluster Configuration Details and Set VPC Subnet IDs
##############################
echo "Step 6: Enter Cluster Configuration Details"
read -p "Enter Cluster Name: " CLUSTER_NAME
read -p "Enter Kubernetes Version (recommended: 1.32): " KUBE_VERSION
read -p "Enter Tag Key: " TAG_KEY
read -p "Enter Tag Value: " TAG_VALUE


TAGS="{\"$TAG_KEY\": \"$TAG_VALUE\"}"

export CLUSTER_NAME
export KUBE_VERSION
export TAGS

echo "Cluster configuration has been set:"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Kubernetes Version: $KUBE_VERSION"
echo "  Tags: $TAGS"
echo ""


read -p "Enter VPC ID to fetch subnets: " VPC_ID

SUBNET_IDS_INPUT=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[?AvailabilityZone!='us-east-1e'].SubnetId" --output text | tr '\n' ',')
SUBNET_IDS_INPUT=${SUBNET_IDS_INPUT%,}
export VPC_ID
echo "Fetched Subnet IDs: $SUBNET_IDS_INPUT"


SUBNET_ARRAY=($SUBNET_IDS_INPUT)
if [ ${#SUBNET_ARRAY[@]} -gt 0 ]; then
  SUBNET_IDS_JSON=$(printf '["%s"' "${SUBNET_ARRAY[0]}")
  for subnet in "${SUBNET_ARRAY[@]:1}"; do
      SUBNET_IDS_JSON=$(printf '%s, "%s"' "$SUBNET_IDS_JSON" "$subnet")
  done
  SUBNET_IDS_JSON=$(printf '%s]' "$SUBNET_IDS_JSON")
else
  SUBNET_IDS_JSON="[]"
fi
export SUBNET_IDS_JSON

echo "VPC Subnet IDs have been set as: $SUBNET_IDS_JSON"
echo ""

##############################
# Step 7: Change Directory to Terraform Stage
##############################
echo "Step 7: Changing directory to Terraform stage"
cd ./assignment/
echo "Current directory: $(pwd)"
echo ""

##############################
# Step 8: Run Terraform Init and Plan
##############################
echo "Step 8: Running 'terraform init'"
terraform init
echo ""
echo "Step 8: Running 'terraform plan'"
terraform plan \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "cluster_version=$KUBE_VERSION" \
  -var "tags=$TAGS" \
  -var "vpc_id=$VPC_ID" \
  -var "vpc_subnet_ids=$SUBNET_IDS_JSON" 
echo ""

##############################
# Step 9: Run Terraform Apply
##############################
echo "Step 9: Warning: Running 'terraform apply' will deploy resources to AWS Cloud and may incur costs."
read -p "Do you want to proceed with 'terraform apply'? (y/n): " APPLY_CONFIRM
if [ "$APPLY_CONFIRM" = "y" ] || [ "$APPLY_CONFIRM" = "Y" ]; then
  terraform apply -auto-approve \
    -var "cluster_name=$CLUSTER_NAME" \
    -var "cluster_version=$KUBE_VERSION" \
    -var "tags=$TAGS" \
    -var "vpc_id=$VPC_ID" \
    -var "vpc_subnet_ids=$SUBNET_IDS_JSON" 
  echo "Terraform apply completed."
else
  echo "Terraform apply aborted by the user."
fi
export KARPENTER_NODE_IAM_ROLE_ARN=$(terraform output -raw karpenter_node_iam_role_arn)

##############################
# Step 10: Configure kubectl 
##############################
echo "Step 10: configuring kubectl"
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $AWS_DEFAULT_REGION 

kubectl get ns


##############################
# Step 11: Deploy Karpenteer NodePool & NodeClass
##############################
echo "Step 11: deploying NodePool & EC2NodeClass"
sed -e "s|\${KARPENTER_ROLE}|$KARPENTER_NODE_IAM_ROLE_ARN|g" -e "s|\${CLUSTER_NAME}|$CLUSTER_NAME|g" ../manifests/nodepool-nodeclass.yaml | kubectl apply -f -