#!/bin/bash
# Manual deployment script to EC2 via SSM

set -e

# Configuration
AWS_REGION="ap-southeast-4"
AWS_PROFILE="ai-steven"
INSTANCE_TAG="Nebulas-host"
ECR_REGISTRY="119778517641.dkr.ecr.ap-southeast-4.amazonaws.com"
ECR_REPO="simple-poc-wg"
CONTAINER_NAME="simple-poc"

echo "=========================================="
echo "Deploying to EC2 via SSM"
echo "=========================================="

# Get instance ID by tag
echo "Looking up instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:name,Values=${INSTANCE_TAG}" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --profile ${AWS_PROFILE} \
  --region ${AWS_REGION})

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "ERROR: No running instance found with tag name=${INSTANCE_TAG}"
    exit 1
fi

echo "Found instance: ${INSTANCE_ID}"
echo

# Deploy via SSM
echo "Deploying container..."
aws ssm send-command \
  --instance-ids ${INSTANCE_ID} \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[
    'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}',
    'docker stop ${CONTAINER_NAME} || true',
    'docker rm ${CONTAINER_NAME} || true',
    'docker pull ${ECR_REGISTRY}/${ECR_REPO}:latest',
    'docker run -d --name ${CONTAINER_NAME} -p 80:80 --restart unless-stopped ${ECR_REGISTRY}/${ECR_REPO}:latest',
    'docker image prune -f'
  ]" \
  --profile ${AWS_PROFILE} \
  --region ${AWS_REGION}

echo
echo "=========================================="
echo "Deployment command sent!"
echo "Check status with: docker ps"
echo "=========================================="
