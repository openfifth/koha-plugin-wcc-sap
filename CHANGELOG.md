# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Improve adjustment matching logic for split orders to work with enhanced Koha core adjustment creation
- Correct fixed tax code for service charges (P3 instead of P1 for 0% tax)

### Added

- Support for WYAD fund mapping to cost center and supplier number

## [0.0.09] - 2024-12-26

### Changed

- Modernized plugin structure with auto-release template integration
- Added GitHub Actions workflow for automated testing and releases
- Implemented proper version synchronization between package.json and plugin file
- Added comprehensive testing framework structure
- Restructured documentation following GitHub best practices

### Added

- CONTRIBUTING.md with development guidelines
- docs/ directory with organized documentation
- Automated KPZ file creation via GitHub Actions
- Real Koha testing against multiple versions (main, stable, oldstable)

## [0.0.08] - 2024-12-26

### Fixed

- Generate one GL line per quantity unit instead of single line per order
- Fix invoice total calculation to account for quantity × unitprice
- Remove FIXME comment as quantity is now properly handled

### Changed

- Each quantity unit now generates separate GL line in SAP export
- Improved accuracy of financial reporting for multi-quantity orders

## [0.0.07] - 2024-11-15

### Added

- Initial SAP finance integration functionality
- Invoice export to SAP finance system
- Configurable transport methods (SFTP, local file)
- Scheduled report generation
- Support for multiple fund codes and cost centers
- Tax code mapping (P1: 20%, P2: 5%, P3: 0%)

[Unreleased]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.09...HEAD
[0.0.09]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.08...v0.0.09
[0.0.08]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.07...v0.0.08
[0.0.07]: https://github.com/openfifth/koha-plugin-wcc-sap/releases/tag/v0.0.07

