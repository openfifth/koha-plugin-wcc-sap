# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.19] - 2026-07-03

## [1.0.18] - 2026-07-03

## [1.0.17] - 2026-05-19

## [1.0.16] - 2026-05-15

## [1.0.15] - 2026-05-15

## [1.0.14] - 2026-05-14

## [1.0.13] - 2026-05-14

## [1.0.12] - 2026-05-14

## [1.0.11] - 2026-05-14

## [1.0.10] - 2026-05-14

## [1.0.9] - 2026-05-13

## [1.0.8] - 2026-05-13

## [1.0.7] - 2026-05-07

### Fixed

- Make the `plugin_sap_cron_runs` schema portable to older MariaDB and MySQL versions: drop the `DEFAULT NULL` clause from the `message TEXT` column. On MariaDB pre-10.2 / MySQL pre-8.0.13 a `TEXT` column cannot take a `DEFAULT` value, so `install()` would throw on those versions, which in turn caused the new Tools page to 500 (since `tool` calls `install()` defensively before `manage_submissions()`)

## [1.0.6] - 2026-05-06

### Added

- Tools-menu access to the submitted-invoices manager: the plugin now defines a `tool` method, so it appears under "Tools › Tool plugins" and the Manage Submitted Invoices page is reachable directly from the Tools menu (matching the pattern already used by the WSCC Oracle plugin)
- Cron-run audit log: a new `plugin_sap_cron_runs` table captures every nightly cron attempt that did real work (status, invoice count, filename, detail message). Recent runs are surfaced as a "Recent cron runs" section at the top of the Tools page so admins can see at a glance whether the cron is healthy and what it has been delivering

### Changed

- "Manage submitted invoices" links on the report page and warning banner now route to `method=tool`, and the page itself uses a Tools breadcrumb. The legacy `method=report&page=manage_submissions` route is retained for backward compatibility

## [1.0.5] - 2026-05-06

### Fixed

- Replace stray "RBKC SAP" copy-paste leftovers in the configuration breadcrumb and report-step1 page with the correct "WCC SAP" label

## [1.0.4] - 2026-05-06

### Changed

- Configuration page: lift Run days back out of the Transport sub-fieldset into its own top-level fieldset, keeping the horizontal day-checkbox layout

### Fixed

- Configuration page: rename the Output select's id from `output` to `report_output` to avoid a CSS clash with an upstream Koha rule on `#output`

## [1.0.3] - 2026-05-06

### Changed

- Configuration page: merge Output and Transport into a single fieldset with Transport as a nested sub-fieldset (Run days now lives under Transport since it only governs upload scheduling); render Run days checkboxes horizontally instead of vertically
- Configuration page: add an explicit "-- None --" option to the Transport server select so an unconfigured state is no longer misrepresented by the first listed transport appearing selected by default

### Fixed

- Configuration page: persist the selected Transport server correctly on re-render — the previous `transport_server.id` comparison against a scalar id always evaluated false, so the saved transport was never marked `selected`

## [1.0.2] - 2026-05-06

### Changed

- Clarify on the configuration page that Transport settings are unused when Output is set to "Local file" — the Transport fieldset is now disabled and an explanation describes the pull-vs-push model
- Move `manage-submissions.tt` JavaScript into the standard `jsinclude` macro and drop the unnecessary jQuery dependency

## [1.0.1] - 2026-03-04

### Fixed

- Route `manage_submissions` action through the `report` method so it resolves correctly from the plugin entry point

### Changed

- Use the Koha `sidebar_menu` pattern for the report aside

## [1.0.0] - 2026-03-04

### Added

- Invoice submission deduplication: track submitted invoices in a new `plugin_sap_submitted_invoices` table to prevent re-submission, with a UI for unlocking previously submitted invoices and a preview warning when invoices in a date range have already been submitted

## [0.3.1] - 2026-03-04

### Fixed

- Normalize `upload_path` to prevent bare concatenation with the filename

## [0.3.0] - 2026-03-04

### Added

- Configurable upload path that falls back to the transport's upload directory when blank

## [0.2.1] - 2026-03-04

### Fixed

- Guard against undefined tax/price fields in GL line generation

## [0.2.0] - 2026-03-04

### Added

- UI-driven fund mappings configuration on the configuration page, replacing the previous hardcoded fund-to-cost-center/supplier mappings

## [0.1.0] - 2026-03-03

### Added

- Logging for the nightly cronjob via `Koha::Logger`

## [0.0.36] - 2026-03-02

### Fixed

- Remove references to non-existent datepicker assets from templates

## [0.0.35] - 2026-03-02

### Changed

- Replace the CGI-based `sftp_upload` action with a REST API endpoint

## [0.0.34] - 2026-03-02

### Fixed

- Port cronjob date-boundary fix and `EDI_EXCL` parsing from the rbkc/wscc plugins

## [0.0.33] - 2026-03-02

Release housekeeping only — no functional changes.

## [0.0.32] - 2026-03-02

### Fixed

- Add CSRF token to the SFTP upload AJAX request

## [0.0.31] - 2025-11-25

### Fixed

- Include adjustment tax in total tax calculation

## [0.0.30] - 2025-11-13

### Changed

- Pin the GitHub Actions workflow to a single branch and image version

## [0.0.29] - 2025-11-13

### Fixed

- Ensure the AP total equals the sum of rounded GL lines plus tax
- Skip £0 adjustments in the SAP export to prevent GL line errors

## [0.0.28] - 2025-10-09

### Fixed

- Correct line ordering in CSV output

## [0.0.27] - 2025-10-08

### Fixed

- Correct `Koha::Number::Price` usage to output integer pence

## [0.0.26] - 2025-10-08

### Fixed

- Implement HMRC-compliant rounding and the "Round Last" principle

## [0.0.25] - 2025-10-06

### Fixed

- Round adjustment amounts to integer pence

## [0.0.24] - 2025-10-03

### Fixed

- Calculate tax-included adjustment amounts for the AP total

## [0.0.23] - 2025-10-03

### Fixed

- Parse service charge tax rates from adjustment notes

## [0.0.22] - 2025-10-01

### Fixed

- Additional corrections for ticket 131752 tax changes (follow-up to 0.0.21)

## [0.0.21] - 2025-09-30

### Fixed

- AP header lines now use tax-inclusive totals while GL ledger lines use tax-exclusive amounts (ticket 131752)

## [0.0.20] - 2025-08-19

### Added

- `Text::CSV` integration for proper CSV formatting and validation
- Robust CSV generation with correct escaping of special characters
- Enhanced download functionality with standards-compliant CSV output
- New `sftp_upload` method with configuration-aware upload/save logic
- Modern Bootstrap UI with cards, badges, and professional styling
- AJAX upload/save functionality with loading states and error handling
- Smart buttons that adapt to configuration (SFTP upload vs local save)
- Scrollable report preview with monospace formatting
- Dynamic button labels based on output configuration

### Changed

- Replace manual string concatenation with the `Text::CSV` writer
- Convert CSV rows to array references for better maintainability
- Improve overall code structure and standards compliance
- Enhanced report template with modern design patterns
- Update UI with WCC branding and improved visual feedback

### Fixed

- Proper handling of quotes, commas, and special characters in CSV output
- Enhanced error handling with user-friendly messages
- Better template parameter passing for UI functionality

## [0.0.19] - 2025-08-07

### Fixed

- Improve adjustment matching logic for split orders so it works with the enhanced Koha core adjustment creation

### Changed

- Sync CHANGELOG with actual release history

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

[Unreleased]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.19...HEAD
[1.0.19]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.18...v1.0.19
[1.0.18]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.17...v1.0.18
[1.0.17]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.16...v1.0.17
[1.0.16]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.15...v1.0.16
[1.0.15]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.14...v1.0.15
[1.0.14]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.13...v1.0.14
[1.0.13]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.12...v1.0.13
[1.0.12]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.11...v1.0.12
[1.0.11]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.10...v1.0.11
[1.0.10]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.3.1...v1.0.0
[0.3.1]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.36...v0.1.0
[0.0.36]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.35...v0.0.36
[0.0.35]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.34...v0.0.35
[0.0.34]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.33...v0.0.34
[0.0.33]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.32...v0.0.33
[0.0.32]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.31...v0.0.32
[0.0.31]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.30...v0.0.31
[0.0.30]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.29...v0.0.30
[0.0.29]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.28...v0.0.29
[0.0.28]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.27...v0.0.28
[0.0.27]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.26...v0.0.27
[0.0.26]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.25...v0.0.26
[0.0.25]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.24...v0.0.25
[0.0.24]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.23...v0.0.24
[0.0.23]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.22...v0.0.23
[0.0.22]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.21...v0.0.22
[0.0.21]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.20...v0.0.21
[0.0.20]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.19...v0.0.20
[0.0.19]: https://github.com/openfifth/koha-plugin-wcc-sap/compare/v0.0.18...v0.0.19
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
