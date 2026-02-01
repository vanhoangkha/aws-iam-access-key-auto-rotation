#!/bin/bash
set -e

# AWS IAM Key Auto-Rotation Deployment Script
# Usage: ./deploy.sh <AWS_REGION> <ADMIN_EMAIL> <ORG_ID>

AWS_REGION="${1:-ap-southeast-1}"
ADMIN_EMAIL="${2}"
ORG_ID="${3}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="asa-iam-rotation-${AWS_ACCOUNT_ID}-${AWS_REGION}"
PREFIX="asa/asa-iam-rotation"

if [ -z "$ADMIN_EMAIL" ] || [ -z "$ORG_ID" ]; then
    echo "Usage: ./deploy.sh <AWS_REGION> <ADMIN_EMAIL> <ORG_ID>"
    echo "Example: ./deploy.sh ap-southeast-1 admin@example.com o-xxxxxxxxxx"
    exit 1
fi

echo "=== AWS IAM Key Auto-Rotation Deployment ==="
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo "Email: $ADMIN_EMAIL"
echo "Org ID: $ORG_ID"
echo ""

# Create S3 bucket
echo "[1/5] Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION 2>/dev/null || echo "Bucket exists"

# Upload Lambda code
echo "[2/5] Uploading Lambda code..."
aws s3 cp Lambda/ s3://$BUCKET_NAME/$PREFIX/Lambda/ --recursive --region $AWS_REGION
aws s3 cp template/ s3://$BUCKET_NAME/$PREFIX/Template/ --recursive --region $AWS_REGION

# Verify SES email
echo "[3/5] Verifying SES email..."
aws ses verify-email-identity --email-address $ADMIN_EMAIL --region $AWS_REGION

# Deploy main stack
echo "[4/5] Deploying CloudFormation stacks..."
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-and-notifier-solution.yaml \
  --stack-name iam-key-auto-rotation \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_REGION \
  --parameter-overrides \
    S3BucketName="$BUCKET_NAME" \
    S3BucketPrefix="$PREFIX" \
    AdminEmailAddress="$ADMIN_EMAIL" \
    AWSOrgID="$ORG_ID" \
    OrgListAccount="$AWS_ACCOUNT_ID" \
    DryRunFlag="True" \
    RunLambdaInVPC="False" \
    VpcId="" \
    SubnetId="" \
    CredentialReplicationRegions=""

aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-list-accounts-role.yaml \
  --stack-name iam-key-rotation-list-accounts-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_REGION \
  --parameter-overrides PrimaryAccountID="$AWS_ACCOUNT_ID"

aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-iam-assumed-roles.yaml \
  --stack-name iam-key-rotation-assumed-roles \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_REGION \
  --parameter-overrides PrimaryAccountID="$AWS_ACCOUNT_ID" AWSOrgID="$ORG_ID"

echo "[5/5] Deployment complete!"
echo ""
echo "=== Next Steps ==="
echo "1. Verify email: Check inbox for AWS verification email"
echo "2. Test (audit): aws lambda invoke --function-name ASA-IAM-Access-Key-Rotation-Function --payload '{\"account\": \"$AWS_ACCOUNT_ID\", \"email\": \"$ADMIN_EMAIL\", \"name\": \"test\"}' /tmp/out.json"
echo "3. Enable enforcement: Update stack with DryRunFlag=False"
