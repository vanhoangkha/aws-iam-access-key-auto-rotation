# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it by emailing the repository owner directly.

Do not create public GitHub issues for security vulnerabilities.

## Security Best Practices

This solution follows AWS security best practices:

- IAM roles use least privilege permissions
- Secrets are stored encrypted in AWS Secrets Manager
- S3 bucket has public access blocked and encryption enabled
- Lambda functions use X-Ray tracing for observability
- CloudWatch logs have retention policies configured
