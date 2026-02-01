# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-02-01

### Security
- Replaced overly permissive managed policies (AmazonSSMFullAccess, AmazonEC2FullAccess) with least privilege inline policies
- Added scoped SSM parameter access for SMTP credentials
- Added minimal VPC network interface permissions

### Fixed
- Fixed bare `except` clause in account_scan.py (now catches `Exception`)
- Fixed potential `None` error in config.py when `CredentialReplicationRegions` is not set
- Fixed missing `org_client` argument in recursive `list_aws_accounts_for_ou()` call

## [1.1.0] - 2026-02-01

### Added
- GitHub Issue templates (bug report, feature request)
- Pull request template
- Dependabot configuration for GitHub Actions
- Security scanning workflow (cfn-nag, Checkov)
- Release workflow for automated releases
- EditorConfig for consistent code style

### Changed
- Improved validation workflow with cfn-lint and yamllint

## [1.0.0] - 2026-02-01

### Added
- Professional README with architecture diagram
- Deployment script (`scripts/deploy.sh`)
- Cleanup script (`scripts/cleanup.sh`)
- GitHub Actions workflow for validation
- Security policy (SECURITY.md)
- .gitignore file

### Changed
- Renamed `Test Units` directory to `tests`
- Updated README with clear deployment instructions

### Fixed
- Python SyntaxWarning: `is not ''` changed to `!= ''` in account_scan.py
