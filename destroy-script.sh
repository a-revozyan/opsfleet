#!/bin/bash
set -e

##############################
# Step 1: Getting values
##############################
echo "Step 1: Enter AWS credentials"
read -p "Enter AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -p "Enter AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "Enter AWS_DEFAULT_REGION: " AWS_DEFAULT_REGION
echo ""

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

echo "AWS credentials have been set."
echo ""


##############################
# Step 2: Getting values
##############################
echo "Step 2: Enter Cluster Configuration Details"
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
# Deleting nodeclass and nodegroup
##############################
echo "Step 11: deploying NodePool & EC2NodeClass"
sed -e "s|\${KARPENTER_ROLE}|$KARPENTER_NODE_IAM_ROLE_ARN|g" -e "s|\${CLUSTER_NAME}|$CLUSTER_NAME|g" ../manifests/nodepool-nodeclass.yaml | kubectl delete -f -


##############################
# Step 3: Change Directory to Terraform Stage
##############################
echo "Step 3: Changing directory to Terraform stage"
cd ./assignment/
echo "Current directory: $(pwd)"
echo ""

##############################
# Step 4: Run Terraform Init and Plan
##############################
echo "Step 4: Running 'terraform init'"
terraform init
echo ""
echo "Step 4: Running 'terraform destroy'"
terraform destroy \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "cluster_version=$KUBE_VERSION" \
  -var "tags=$TAGS" \
  -var "vpc_id=$VPC_ID" \
  -var "vpc_subnet_ids=$SUBNET_IDS_JSON" 
echo ""