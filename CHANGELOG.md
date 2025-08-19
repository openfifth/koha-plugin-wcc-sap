# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Text::CSV integration for proper CSV formatting and validation
- Robust CSV generation with correct escaping of special characters
- Enhanced download functionality with standards-compliant CSV output
- New `sftp_upload` method with configuration-aware upload/save logic
- Modern Bootstrap UI with cards, badges, and professional styling
- AJAX upload/save functionality with loading states and error handling
- Smart buttons that adapt to configuration (SFTP upload vs local save)
- Scrollable report preview with monospace formatting
- Dynamic button labels based on output configuration

### Changed

- Replace manual string concatenation with Text::CSV writer
- Convert CSV rows to array references for better maintainability
- Improve code structure and standards compliance
- Enhanced report template with modern design patterns
- Update UI with WCC branding and improved visual feedback
- Improve user experience with better visual feedback

### Fixed

- Improve adjustment matching logic for split orders to work with enhanced Koha core adjustment creation
- Proper handling of quotes, commas, and special characters in CSV output
- Enhanced error handling with user-friendly messages
- Better template parameter passing for UI functionality

## [0.0.18] - 2025-07-22

### Fixed

- Correct fixed tax code for service charges (P3 instead of P1 for 0% tax)

## [0.0.17] - 2025-07-03

### Fixed

- Add fixed tax code for service charges

## [0.0.16] - 2025-07-02

### Added

- Support for WYAD fund mapping to cost center and supplier number

## [0.0.15] - 2025-07-01

### Changed

- Code tidying and maintenance (excluding \_generate_report function)

## [0.0.14] - 2025-07-01

### Fixed

- Improve split order handling for invoice adjustments

## [0.0.13] - 2025-06-30

### Added

- Invoice adjustments support in SAP report generation

### Fixed

- Update adjustment line ID extraction to use EDI Line number

## [0.0.12] - 2025-06-27

### Changed

- Add package-lock.json for dependency management

## [0.0.11] - 2025-06-27

### Changed

- Rebrand from PTFS Europe to Open Fifth
- Update CI to use OpenFifth WCC Koha branch for testing
- Fix version string handling

## [0.0.10] - 2025-06-26

### Changed

- Modernize plugin structure with auto-release template integration
- Rebrand from PTFS Europe to Open Fifth

## [0.0.9] - 2025-06-26

### Fixed

- Generate one GL line per quantity unit instead of single line per order
- Allow cron to die silently when there are no invoices to process

### Changed

- Modernize plugin structure with auto-release template integration
- Rebrand from PTFS Europe to Open Fifth

## [0.0.8] - 2025-06-26

### Fixed

- Generate one GL line per quantity unit instead of single line per order

### Changed

- Rebrand from PTFS Europe to Open Fifth
- Modernize plugin structure with auto-release template integration

## [0.0.07] - 2024-11-15

### Fixed

- Make unitprice tax inclusive

## [0.0.06] - 2024-11-15

### Fixed

- Correct newline handling in output formatting

## [0.0.05] - 2024-11-15

### Fixed

- Fix newline logic in report generation

## [0.0.04] - 2024-11-15

### Changed

- Alter newline logic for better formatting

## [0.0.03] - 2024-11-15

### Fixed

- Blank 'statistical' field in output

## [0.0.02] - 2024-11-15

### Fixed

- Correct mappings for WCC/SAP integration

## [0.0.01] - 2024-11-15

### Added

- Initial SAP finance integration functionality
- Invoice export to SAP finance system
- Configurable transport methods (SFTP, local file)
- Scheduled report generation
- Support for multiple fund codes and cost centers
- Tax code mapping (P1: 20%, P2: 5%, P3: 0%)

[Unreleased]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.18...HEAD
[0.0.18]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.17...v0.0.18
[0.0.17]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.16...v0.0.17
[0.0.16]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.15...v0.0.16
[0.0.15]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.14...v0.0.15
[0.0.14]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.13...v0.0.14
[0.0.13]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.12...v0.0.13
[0.0.12]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.11...v0.0.12
[0.0.11]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.10...v0.0.11
[0.0.10]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.9...v0.0.10
[0.0.9]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.8...v0.0.9
[0.0.8]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.7...v0.0.8
[0.0.01]: https://github.com/openfifth/koha-plugin-wcc-sap/releases/tag/v0.0.01
