#!/bin/bash
set -e

# Cleanup script for AWS IAM Key Auto-Rotation
# Usage: ./cleanup.sh <AWS_REGION>

AWS_REGION="${1:-ap-southeast-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="asa-iam-rotation-${AWS_ACCOUNT_ID}-${AWS_REGION}"

echo "=== Cleaning up IAM Key Auto-Rotation ==="
echo "Region: $AWS_REGION"
echo ""

# Delete stacks
echo "[1/3] Deleting CloudFormation stacks..."
aws cloudformation delete-stack --stack-name iam-key-rotation-assumed-roles --region $AWS_REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name iam-key-rotation-list-accounts-role --region $AWS_REGION 2>/dev/null || true
aws cloudformation wait stack-delete-complete --stack-name iam-key-rotation-assumed-roles --region $AWS_REGION 2>/dev/null || true
aws cloudformation wait stack-delete-complete --stack-name iam-key-rotation-list-accounts-role --region $AWS_REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name iam-key-auto-rotation --region $AWS_REGION 2>/dev/null || true
aws cloudformation wait stack-delete-complete --stack-name iam-key-auto-rotation --region $AWS_REGION 2>/dev/null || true

# Empty and delete S3 bucket
echo "[2/3] Deleting S3 bucket..."
aws s3 rm s3://$BUCKET_NAME --recursive --region $AWS_REGION 2>/dev/null || true
aws s3 rb s3://$BUCKET_NAME --region $AWS_REGION 2>/dev/null || true

echo "[3/3] Cleanup complete!"
