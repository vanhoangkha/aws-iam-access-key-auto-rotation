# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
