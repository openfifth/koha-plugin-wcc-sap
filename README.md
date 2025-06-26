# koha-plugin-wcc-sap

A Koha plugin to manage finance integration with SAP for Westminster City Council (WCC).

## Features

- Automated invoice export to SAP finance system
- Configurable transport methods (SFTP, local file)
- Scheduled report generation based on configured days
- Support for multiple fund codes and cost centers
- Quantity-based line replication for detailed reporting
- Tax code mapping (P1: 20%, P2: 5%, P3: 0%)

## Installation

1. Download the latest `.kpz` file from the [Releases](https://github.com/openfifth/koha-plugin-wcc-sap/releases) page
2. In Koha, go to Tools > Plugins
3. Upload the `.kpz` file using the plugin upload feature
4. Enable the plugin

## Configuration

After installation, configure the plugin:

1. Go to Tools > Plugins > SAP Finance Integration > Configure
2. Set up transport server (if using SFTP)
3. Select the days for automated report generation
4. Choose output method (upload or local file)

## Usage

### Manual Report Generation

1. Go to Tools > Plugins > SAP Finance Integration > Run
2. Select date range for the report
3. Choose output format (HTML or text)

### Automated Reports

The plugin will automatically generate and send reports based on your configured schedule.

## Contributing

Interested in contributing to this plugin? Please see our [Contributing Guide](CONTRIBUTING.md) for development setup, testing guidelines, and release processes.

## Documentation

For additional documentation, see the [docs/](docs/) directory:
- [Documentation Index](docs/README.md)
- [Contributing Guide](CONTRIBUTING.md)

## Support

- **Issues**: [GitHub Issues](https://github.com/openfifth/koha-plugin-wcc-sap/issues)
- **Author**: Open Fifth
- **License**: GPL-3.0
