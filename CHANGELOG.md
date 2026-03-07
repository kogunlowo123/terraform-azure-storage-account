# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added

- Initial release of the Azure Storage Account Terraform module
- Storage Account with configurable tier, replication, kind, and access tier
- Blob container management with access level control and metadata
- File share management with quota, access tier, and ACL support
- Storage queue management with metadata
- Storage table management with ACL support
- Blob properties: versioning, change feed, retention policies, and CORS rules
- Lifecycle management policies with tiering and deletion rules
- Static website hosting configuration
- Account-level immutability policies
- Network rules with IP, VNet, and private link access controls
- Private endpoint connectivity with DNS zone groups
- Managed identity support (SystemAssigned and UserAssigned)
- Customer-managed key encryption
- Infrastructure encryption support
- Diagnostic settings for all storage services
- Comprehensive examples: basic, advanced, and complete
