#!/bin/bash
set -e

# Set your AWS region
AWS_REGION="us-east-1"
# Get your account ID from AWS
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# ECR repository name (from verify-ecr.json)
ECR_REPO="flask-crud-app"

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build the image
echo "Building the Docker image..."
docker build -t $ECR_REPO:latest .

# Tag the image for ECR
echo "Tagging the image..."
docker tag $ECR_REPO:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

# Push the image to ECR
echo "Pushing the image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

# Update the ECS service to force new deployment
echo "Updating ECS service to force new deployment..."
aws ecs update-service --cluster flask-app-cluster --service flask-app-service --force-new-deployment --region $AWS_REGION

echo "Redeployment triggered successfully!" 