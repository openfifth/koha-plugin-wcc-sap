# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Koha plugin for SAP finance integration that enables invoice export to SAP finance systems. The plugin is built for WCC (Westminster City Council) and follows the standard Koha plugin architecture.

## Architecture

- **Main Plugin File**: `Koha/Plugin/Com/PTFSEurope/SAP.pm` - Core plugin logic with version 0.0.07
- **Templates**: Template Toolkit (`.tt`) files in `Koha/Plugin/Com/PTFSEurope/SAP/` for UI components:
  - `configure.tt` - Plugin configuration interface
  - `report-step1.tt` - Initial report generation form
  - `report-step2-html.tt` - HTML report output
  - `report-step2-txt.tt` - Text report output
- **Build Tools**: Node.js utilities for version management and release automation
- **Release System**: Automated .kpz (Koha Plugin Zip) file generation and GitHub release management

## Development Commands

### Release Management (Modern Approach)
```bash
npm run release:patch    # For bug fixes (0.0.7 → 0.0.8)
npm run release:minor    # For new features (0.0.7 → 0.1.0)
npm run release:major    # For breaking changes (0.0.7 → 1.0.0)
```

### Legacy Release Management
```bash
npm run release
# Equivalent to: bash ./release_kpz.sh
```
Creates a .kpz plugin file, validates version updates, commits changes, creates git tags, and pushes to GitHub.

### Manual Plugin Build
```bash
zip -r koha-plugin-sap.kpz Koha/
```

### Version Management
```bash
npm run version:patch   # Update package.json version (patch)
npm run version:minor   # Update package.json version (minor)
npm run version:major   # Update package.json version (major)
```

### Version Checking
```bash
node checkVersionNumber.js version    # Get current version
node checkVersionNumber.js filename   # Get plugin filename
```

### Testing
```bash
prove t/                # Run test suite
prove t/00-load.t      # Run specific test
```

### Remote Validation
```bash
node checkRemotes.js check $(git remote -v)
```

## Key Components

### Plugin Structure
- Inherits from `Koha::Plugins::Base`
- Uses Modern Perl with strict/warnings
- Integrates with Koha's file transport system for SAP data delivery
- Supports both file output and remote upload via transports

### Version Management
- Version defined in `SAP.pm` as `our $VERSION = '0.0.07'`
- Automated version checking prevents duplicate releases
- Git tags created automatically matching version numbers

### Report Generation
- Two-step report process with date range selection
- Supports both HTML and text output formats
- Automatic scheduling based on configured transport days
- File naming follows SAP conventions with timestamp

### Transport Configuration
- Integrates with Koha::File::Transports for data delivery
- Supports multiple transport methods (SFTP, etc.)
- Configurable upload paths: `IN/LB01/WK/{filename}`

## GitHub Actions Automation

### Automated Release Process
- GitHub Actions workflow (`.github/workflows/main.yml`) triggers on:
  - Pushes to `main` branch
  - Git tags matching `v*` pattern
- Automatically creates .kpz file and GitHub releases
- Requires `contents: write` permissions

### Workflow Steps
1. Checkout code
2. Extract version and filename from plugin
3. Create GitHub release with .kpz file attached

## Development Notes

- Basic test framework configured in `t/` directory
- Plugin packaging uses zip compression of the `Koha/` directory  
- Version synchronization between `package.json` and `.pm` file required
- Release script automatically excludes template repository remotes
- Uses Template Toolkit for all UI components
- GitHub Actions handles automated releases when tags are pushed