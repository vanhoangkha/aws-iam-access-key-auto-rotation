# AWS IAM Access Key Auto-Rotation

Automated solution for rotating AWS IAM User Access Keys following security best practices.

## Overview

This solution automatically manages IAM Access Key lifecycle:

| Day | Action |
|-----|--------|
| 90 | Rotate - Create new key, store in Secrets Manager |
| 100 | Disable - Deactivate old key |
| 110 | Delete - Remove old key permanently |

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  EventBridge    │────▶│  Account Inventory   │────▶│  Key Rotation   │
│  (24h schedule) │     │  Lambda              │     │  Lambda         │
└─────────────────┘     └──────────────────────┘     └────────┬────────┘
                                                              │
                        ┌──────────────────────┐              │
                        │  Notifier Lambda     │◀─────────────┤
                        │  (SES Email)         │              │
                        └──────────────────────┘              ▼
                                                     ┌─────────────────┐
                                                     │ Secrets Manager │
                                                     │ (New Keys)      │
                                                     └─────────────────┘
```

## Prerequisites

- AWS Account with Organizations (for multi-account)
- Amazon SES configured (verified email/domain)
- S3 bucket for Lambda code storage

## Quick Start

### 1. Prepare S3 Bucket

```bash
BUCKET_NAME="asa-iam-rotation-${AWS_ACCOUNT_ID}-${AWS_REGION}"
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

aws s3 cp Lambda/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Lambda/ --recursive
aws s3 cp template/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Template/ --recursive
```

### 2. Verify SES Email

```bash
aws ses verify-email-identity --email-address your-email@example.com --region $AWS_REGION
```

### 3. Deploy CloudFormation Stacks

```bash
# Main Solution
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-and-notifier-solution.yaml \
  --stack-name iam-key-auto-rotation \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    S3BucketName="$BUCKET_NAME" \
    S3BucketPrefix="asa/asa-iam-rotation" \
    AdminEmailAddress="your-email@example.com" \
    AWSOrgID="o-xxxxxxxxxx" \
    OrgListAccount="$AWS_ACCOUNT_ID" \
    DryRunFlag="True"

# List Accounts Role
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-list-accounts-role.yaml \
  --stack-name iam-key-rotation-list-accounts-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    PrimaryAccountID="$AWS_ACCOUNT_ID"

# IAM Assumed Roles
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-iam-assumed-roles.yaml \
  --stack-name iam-key-rotation-assumed-roles \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    PrimaryAccountID="$AWS_ACCOUNT_ID" \
    AWSOrgID="o-xxxxxxxxxx"
```

Or use the deployment script:

```bash
./scripts/deploy.sh <AWS_REGION> <ADMIN_EMAIL> <ORG_ID>
```

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DryRunFlag` | True | Audit mode (True) or Enforcement mode (False) |
| `RotationPeriod` | 90 | Days before key rotation |
| `InactivePeriod` | 100 | Days before key deactivation |
| `RecoveryGracePeriod` | 10 | Grace period before deletion |

## Testing

Test rotation in audit mode:

```bash
aws lambda invoke \
  --function-name ASA-IAM-Access-Key-Rotation-Function \
  --payload '{"account": "123456789012", "email": "user@example.com", "name": "my-account"}' \
  output.json
```

Force rotation for specific user:

```bash
aws lambda invoke \
  --function-name ASA-IAM-Access-Key-Rotation-Function \
  --payload '{"account": "123456789012", "email": "user@example.com", "name": "my-account", "ForceRotate": "username"}' \
  output.json
```

## Retrieving Rotated Keys

New keys are stored in AWS Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id Account_${ACCOUNT_ID}_User_${USERNAME}_AccessKey \
  --query SecretString --output text
```

## Project Structure

```
├── CloudFormation/
│   ├── ASA-iam-key-auto-rotation-and-notifier-solution.yaml
│   ├── ASA-iam-key-auto-rotation-iam-assumed-roles.yaml
│   ├── ASA-iam-key-auto-rotation-list-accounts-role.yaml
│   └── ASA-iam-key-auto-rotation-vpc-endpoints.yaml
├── Lambda/
│   ├── account_inventory.zip
│   ├── access_key_auto_rotation.zip
│   └── notifier.zip
├── scripts/
│   ├── deploy.sh
│   └── cleanup.sh
├── template/
│   └── iam-auto-key-rotation-enforcement.html
├── tests/
│   └── *.json
└── Docs/
    └── ASA IAM Key Rotation Runbook(v3).pdf
```

## Exempting Users

Create an IAM Group named `IAMKeyRotationExemptionGroup` and add users to exempt from rotation.

## Documentation

See [Docs/ASA IAM Key Rotation Runbook(v3).pdf](Docs/ASA%20IAM%20Key%20Rotation%20Runbook(v3).pdf) for detailed documentation.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for security issue notifications.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
