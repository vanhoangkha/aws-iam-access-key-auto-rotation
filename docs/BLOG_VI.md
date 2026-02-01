# Tự động xoay vòng Access Key AWS IAM với Lambda và Secrets Manager

## Giới thiệu

Quản lý Access Key của IAM User là một trong những thách thức bảo mật lớn nhất trên AWS. Theo AWS Best Practices, Access Key nên được rotate (xoay vòng) định kỳ mỗi 90 ngày. Tuy nhiên, với hàng trăm IAM User trong tổ chức, việc làm thủ công này gần như không khả thi.

Bài viết này hướng dẫn bạn triển khai giải pháp **tự động xoay vòng Access Key** sử dụng AWS Lambda, Secrets Manager và CloudFormation.

## Vấn đề cần giải quyết

- Access Key không được rotate định kỳ → Rủi ro bảo mật cao
- Quản lý thủ công tốn thời gian và dễ sai sót
- Khó theo dõi key nào đã hết hạn, key nào cần rotate
- Người dùng không biết key mới sau khi rotate

## Giải pháp

### Kiến trúc tổng quan

```
EventBridge (24h) → Account Inventory Lambda → Key Rotation Lambda → Secrets Manager
                                                       ↓
                                              Notifier Lambda (SES Email)
```

### Quy trình xử lý

| Ngày | Hành động | Mô tả |
|------|-----------|-------|
| 90 | **Rotate** | Tạo Access Key mới, lưu vào Secrets Manager |
| 100 | **Disable** | Vô hiệu hóa Access Key cũ |
| 110 | **Delete** | Xóa vĩnh viễn Access Key cũ |

## Hướng dẫn triển khai

### Yêu cầu

- Tài khoản AWS với AWS Organizations
- Amazon SES đã verify email/domain
- AWS CLI đã cấu hình

### Bước 1: Clone repository

```bash
git clone https://github.com/vanhoangkha/aws-iam-access-key-auto-rotation.git
cd aws-iam-access-key-auto-rotation
```

### Bước 2: Chuẩn bị S3 Bucket

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export BUCKET_NAME="asa-iam-rotation-${AWS_ACCOUNT_ID}-${AWS_REGION}"

# Tạo bucket và upload code
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
aws s3 cp Lambda/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Lambda/ --recursive
aws s3 cp template/ s3://$BUCKET_NAME/asa/asa-iam-rotation/Template/ --recursive
```

### Bước 3: Verify email SES

```bash
aws ses verify-email-identity --email-address your-email@example.com --region $AWS_REGION
```

Kiểm tra inbox và click link xác nhận.

### Bước 4: Deploy CloudFormation

```bash
# Lấy Organization ID
ORG_ID=$(aws organizations describe-organization --query 'Organization.Id' --output text)

# Deploy stack chính
aws cloudformation deploy \
  --template-file CloudFormation/ASA-iam-key-auto-rotation-and-notifier-solution.yaml \
  --stack-name iam-key-auto-rotation \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    S3BucketName="$BUCKET_NAME" \
    S3BucketPrefix="asa/asa-iam-rotation" \
    AdminEmailAddress="your-email@example.com" \
    AWSOrgID="$ORG_ID" \
    OrgListAccount="$AWS_ACCOUNT_ID" \
    DryRunFlag="True"
```

Hoặc sử dụng script deploy:

```bash
./scripts/deploy.sh us-east-1 your-email@example.com o-xxxxxxxxxx
```

## Cấu hình

| Tham số | Mặc định | Mô tả |
|---------|----------|-------|
| `DryRunFlag` | `True` | `True` = Chế độ audit (chỉ thông báo), `False` = Chế độ thực thi |
| `RotationPeriod` | `90` | Số ngày trước khi rotate key |
| `InactivePeriod` | `100` | Số ngày trước khi vô hiệu hóa key |
| `RecoveryGracePeriod` | `10` | Thời gian chờ trước khi xóa vĩnh viễn |

## Kiểm tra hoạt động

### Test chế độ Audit

```bash
aws lambda invoke \
  --function-name ASA-IAM-Access-Key-Rotation-Function \
  --payload '{"account": "123456789012", "email": "user@example.com", "name": "my-account"}' \
  --cli-binary-format raw-in-base64-out \
  output.json
```

### Xem logs

```bash
aws logs tail /aws/lambda/ASA-IAM-Access-Key-Rotation-Function --since 5m
```

### Lấy Access Key mới

Sau khi key được rotate, lấy key mới từ Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id Account_123456789012_User_username_AccessKey \
  --query SecretString --output text
```

## Loại trừ User khỏi rotation

Thêm user vào IAM Group `IAMKeyRotationExemptionGroup` để không bị rotate tự động.

## Bảo mật

Giải pháp tuân thủ AWS Security Best Practices:

- IAM Role sử dụng quyền tối thiểu (Least Privilege)
- Access Key mới được mã hóa trong Secrets Manager
- Hỗ trợ triển khai trong VPC với Private Endpoints
- Có thể tùy chỉnh chính sách rotation

## Kết luận

Giải pháp này giúp tự động hóa việc quản lý vòng đời Access Key, giảm thiểu rủi ro bảo mật và tiết kiệm thời gian quản trị. Với chế độ DryRun, bạn có thể kiểm tra trước khi áp dụng thực tế.

## Tài liệu tham khảo

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Rotating IAM Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

---

**Source code:** [github.com/vanhoangkha/aws-iam-access-key-auto-rotation](https://github.com/vanhoangkha/aws-iam-access-key-auto-rotation)
