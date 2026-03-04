#!/usr/bin/perl

use Modern::Perl;
use Test::More tests => 8;
use Test::Exception;
use Path::Tiny qw(path);

# Get the plugin directory path
my $plugin_dir = $ENV{KOHA_PLUGIN_DIR} || '.';
my $package_json_path = path($plugin_dir)->child('package.json');

# Add plugin directory to @INC
unshift @INC, $plugin_dir;
use Mojo::JSON qw(encode_json);

use_ok('Koha::Plugin::Com::OpenFifth::SAP') || print "Bail out!\n";

my $plugin = Koha::Plugin::Com::OpenFifth::SAP->new();

# Seed fund mappings so mapping methods have data to read
$plugin->store_data({ fund_field_mappings => encode_json({
    WAFI => { costcenter => 'W26315', suppliernumber => '4539' },
    WERE => { costcenter => 'W26353', suppliernumber => '5190' },
    WHLS => { costcenter => 'W26352', suppliernumber => '4539' },
    WPER => { costcenter => 'W26315', suppliernumber => '4625' },
}) });

# Test fund mapping methods
subtest 'Fund to cost center mapping' => sub {
    plan tests => 4;

    is($plugin->_map_fund_to_costcenter('WAFI'), 'W26315', 'WAFI maps to correct cost center');
    is($plugin->_map_fund_to_costcenter('WERE'), 'W26353', 'WERE maps to correct cost center');
    is($plugin->_map_fund_to_costcenter('WHLS'), 'W26352', 'WHLS maps to correct cost center');
    is($plugin->_map_fund_to_costcenter('INVALID'), 'UNMAPPED:INVALID', 'Invalid fund returns UNMAPPED with fund code');
};

subtest 'Fund to supplier number mapping' => sub {
    plan tests => 4;

    is($plugin->_map_fund_to_suppliernumber('WAFI'), '4539', 'WAFI maps to correct supplier number');
    is($plugin->_map_fund_to_suppliernumber('WERE'), '5190', 'WERE maps to correct supplier number');
    is($plugin->_map_fund_to_suppliernumber('WPER'), '4625', 'WPER maps to correct supplier number');
    is($plugin->_map_fund_to_suppliernumber('INVALID'), 'UNMAPPED:INVALID', 'Invalid fund returns UNMAPPED with fund code');
};

# Test filename generation
subtest 'Filename generation' => sub {
    plan tests => 2;

    my $filename = $plugin->_generate_filename();
    like($filename, qr/^WC_LB01_\d{14}\.txt$/, 'Filename follows correct pattern');
    is(length($filename), 26, 'Filename has correct length');
};

# Test cron parameter handling
subtest '_generate_report with cron parameter' => sub {
    plan tests => 2;

    my $start_date = DateTime->new(year => 2024, month => 1, day => 1);
    my $end_date   = DateTime->new(year => 2024, month => 1, day => 31);

    lives_ok {
        $plugin->_generate_report($start_date, $end_date, 'cron');
    } '_generate_report accepts cron parameter';

    lives_ok {
        $plugin->_generate_report($start_date, $end_date);
    } '_generate_report works without cron parameter';
};

# Test metadata structure
subtest 'Plugin metadata' => sub {
    plan tests => 6;

    my $metadata = $plugin->{metadata};

    ok($metadata->{name},            'Plugin has name');
    ok($metadata->{author},          'Plugin has author');
    ok($metadata->{version},         'Plugin has version');
    ok($metadata->{description},     'Plugin has description');
    ok($metadata->{date_authored},   'Plugin has date_authored');
    ok($metadata->{minimum_version}, 'Plugin has minimum_version');
};

# Test required plugin methods exist
subtest 'Required plugin methods' => sub {
    plan tests => 10;

    can_ok($plugin, 'configure');
    can_ok($plugin, 'cronjob_nightly');
    can_ok($plugin, 'report');
    can_ok($plugin, '_generate_report');
    can_ok($plugin, '_generate_filename');
    can_ok($plugin, 'new');
    can_ok($plugin, 'manage_submissions');
    can_ok($plugin, 'install');
    can_ok($plugin, '_mark_invoices_submitted');
    can_ok($plugin, '_get_submitted_invoice_numbers');
};

# Test configuration parameter handling
subtest 'Configuration handling' => sub {
    plan tests => 2;

    lives_ok {
        $plugin->store_data({ test_key => 'test_value' });
    } 'Can store configuration data';

    my $retrieved = $plugin->retrieve_data('test_key');
    is($retrieved, 'test_value', 'Can retrieve stored configuration data');
};

done_testing();
