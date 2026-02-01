# AWS IAM Access Key Auto-Rotation

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-yellow.svg)](https://opensource.org/licenses/MIT-0)
[![AWS](https://img.shields.io/badge/AWS-CloudFormation-orange)](https://aws.amazon.com/cloudformation/)
[![Python](https://img.shields.io/badge/Python-3.13-blue)](https://www.python.org/)

Automated AWS IAM access key rotation solution using Lambda, Secrets Manager, and CloudFormation. Enforce security best practices by automatically rotating, disabling, and deleting IAM user access keys based on configurable policies.

## Features

- **Automated Key Lifecycle Management** - Rotate keys at 90 days, disable at 100 days, delete at 110 days
- **Multi-Account Support** - Works across AWS Organizations with cross-account IAM roles
- **Secure Key Storage** - New credentials stored encrypted in AWS Secrets Manager
- **Email Notifications** - Alert users via Amazon SES before and after key actions
- **Audit Mode** - Test the solution without making changes (DryRun)
- **Exemption Support** - Exclude specific users via IAM group membership
- **VPC Support** - Optional deployment within VPC for enhanced security

## How It Works

| Day | Action | Description |
|-----|--------|-------------|
| 90 | **Rotate** | Create new access key, store in Secrets Manager |
| 100 | **Disable** | Deactivate old access key |
| 110 | **Delete** | Permanently remove old access key |

## Architecture

![Architecture Diagram](docs/architecture.png)

## Prerequisites

- AWS Account with [AWS Organizations](https://aws.amazon.com/organizations/) enabled
- [Amazon SES](https://aws.amazon.com/ses/) configured with verified email/domain
- AWS CLI configured with appropriate permissions

## Quick Start

### Option 1: Using Deploy Script

```bash
git clone https://github.com/vanhoangkha/aws-iam-access-key-auto-rotation.git
cd aws-iam-access-key-auto-rotation
./scripts/deploy.sh us-east-1 admin@example.com o-xxxxxxxxxx
```

### Option 2: Manual Deployment

```bash
# Set variables
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export BUCKET_NAME="asa-iam-rotation-${AWS_ACCOUNT_ID}-${AWS_REGION}"

# Create S3 bucket and upload code
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
aws s3 cp Lambda/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Lambda/ --recursive
aws s3 cp template/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Template/ --recursive

# Verify SES email
aws ses verify-email-identity --email-address admin@example.com --region $AWS_REGION

# Deploy CloudFormation stacks
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-and-notifier-solution.yaml \
  --stack-name iam-key-auto-rotation \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    S3BucketName="$BUCKET_NAME" \
    S3BucketPrefix="asa/asa-iam-rotation" \
    AdminEmailAddress="admin@example.com" \
    AWSOrgID="o-xxxxxxxxxx" \
    OrgListAccount="$AWS_ACCOUNT_ID" \
    DryRunFlag="True"
```

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DryRunFlag` | `True` | `True` = Audit mode (notifications only), `False` = Enforcement mode |
| `RotationPeriod` | `90` | Days before access key rotation |
| `InactivePeriod` | `100` | Days before access key deactivation |
| `RecoveryGracePeriod` | `10` | Grace period before permanent deletion |

## Usage

### Test in Audit Mode

```bash
aws lambda invoke \
  --function-name ASA-IAM-Access-Key-Rotation-Function \
  --payload '{"account": "123456789012", "email": "user@example.com", "name": "my-account"}' \
  --cli-binary-format raw-in-base64-out \
  output.json
```

### Force Rotate Specific User

```bash
aws lambda invoke \
  --function-name ASA-IAM-Access-Key-Rotation-Function \
  --payload '{"account": "123456789012", "email": "user@example.com", "name": "my-account", "ForceRotate": "username"}' \
  --cli-binary-format raw-in-base64-out \
  output.json
```

### Retrieve Rotated Keys

```bash
aws secretsmanager get-secret-value \
  --secret-id Account_123456789012_User_username_AccessKey \
  --query SecretString --output text
```

## Exempting Users

Add users to the `IAMKeyRotationExemptionGroup` IAM group to exclude them from automatic rotation.

## Project Structure

```
├── CloudFormation/          # Infrastructure as Code templates
├── Lambda/                  # Lambda function packages
├── scripts/                 # Deployment and cleanup scripts
├── template/                # Email notification templates
├── tests/                   # Test event payloads
└── Docs/                    # Documentation
```

## Security

This solution follows AWS security best practices:

- IAM roles use least privilege permissions
- Secrets stored encrypted in AWS Secrets Manager
- Support for VPC deployment with private endpoints
- Configurable key rotation policies

For security issues, see [CONTRIBUTING.md](CONTRIBUTING.md#security-issue-notifications).

## Related Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Rotating IAM Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_RotateAccessKey)

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT-0 License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
