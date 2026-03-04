#!/usr/bin/perl

# Migrate hardcoded WCC SAP fund mappings into plugin configuration storage.
#
# Run once after upgrading to the version that introduced UI-driven fund
# mappings.  Safe to run multiple times — it will not overwrite existing
# configuration unless --force is passed.
#
# Usage:
#   perl scripts/migrate_fund_mappings.pl
#   perl scripts/migrate_fund_mappings.pl --force   # overwrite existing

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Mojo::JSON   qw(encode_json decode_json);

# Koha environment
use C4::Context;

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

my $PLUGIN_CLASS = 'Koha::Plugin::Com::OpenFifth::SAP';
my $DATA_KEY     = 'fund_field_mappings';

my %MAPPINGS = (
    WAFI   => { costcenter => 'W26315', suppliernumber => '4539' },
    WANF   => { costcenter => 'W26315', suppliernumber => '4539' },
    WARC   => { costcenter => 'W26311', suppliernumber => '4539' },
    WBAS   => { costcenter => 'W26315', suppliernumber => '4539' },
    WCFI   => { costcenter => 'W26315', suppliernumber => '4539' },
    WCHG   => { costcenter => 'W26315', suppliernumber => '4539' },
    WCHI   => { costcenter => 'W26315', suppliernumber => '4539' },
    WCNF   => { costcenter => 'W26315', suppliernumber => '4539' },
    WCOM   => { costcenter => 'W26315', suppliernumber => '4539' },
    WEBE   => { costcenter => 'W26315', suppliernumber => '4539' },
    WELE   => { costcenter => 'W26315', suppliernumber => '4539' },
    WERE   => { costcenter => 'W26353', suppliernumber => '5190' },
    WFSO   => { costcenter => 'W26315', suppliernumber => '4539' },
    WHLS   => { costcenter => 'W26352', suppliernumber => '4539' },
    WLPR   => { costcenter => 'W26315', suppliernumber => '4539' },
    WNHC   => { costcenter => 'W26315', suppliernumber => '4539' },
    WNSO   => { costcenter => 'W26315', suppliernumber => '4539' },
    WPER   => { costcenter => 'W26315', suppliernumber => '4625' },
    WRCHI  => { costcenter => 'W26315', suppliernumber => '4539' },
    WREF   => { costcenter => 'W26353', suppliernumber => '4539' },
    WREFSO => { costcenter => 'W26315', suppliernumber => '4539' },
    WREP   => { costcenter => 'W26315', suppliernumber => '4539' },
    WREQ   => { costcenter => 'W26315', suppliernumber => '4539' },
    WRFI   => { costcenter => 'W26315', suppliernumber => '4539' },
    WRNF   => { costcenter => 'W26315', suppliernumber => '4539' },
    WSHC   => { costcenter => 'W26353', suppliernumber => '4539' },
    WSPO   => { costcenter => 'W26315', suppliernumber => '4539' },
    WSSS   => { costcenter => 'W26315', suppliernumber => '4539' },
    WVAT   => { costcenter => 'W26315', suppliernumber => '4539' },
    WWML   => { costcenter => 'W26352', suppliernumber => '4539' },
    WYAD   => { costcenter => 'W26315', suppliernumber => '4539' },
);

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

my $force = 0;
GetOptions( 'force' => \$force ) or die "Usage: $0 [--force]\n";

my $dbh = C4::Context->dbh;

# Check for existing configuration
my ($existing) = $dbh->selectrow_array(
    'SELECT plugin_value FROM plugin_data WHERE plugin_class = ? AND plugin_key = ?',
    undef, $PLUGIN_CLASS, $DATA_KEY
);

my $already_set = $existing && $existing ne '{}';

if ( $already_set && !$force ) {
    my $current = eval { decode_json($existing) } || {};
    my $count = scalar keys %$current;
    print "Fund mappings already configured ($count funds stored).\n";
    print "Run with --force to overwrite.\n";
    exit 0;
}

if ( $already_set && $force ) {
    print "Overwriting existing fund mappings (--force specified).\n";
}

# Write mappings
my $json = encode_json( \%MAPPINGS );
$dbh->do(
    'REPLACE INTO plugin_data (plugin_class, plugin_key, plugin_value) VALUES (?, ?, ?)',
    undef, $PLUGIN_CLASS, $DATA_KEY, $json
);

my $count = scalar keys %MAPPINGS;
print "Done. Migrated $count fund mappings into plugin configuration.\n";
print "You can now view and edit them via: Plugins > SAP Finance Integration > Configure.\n";
