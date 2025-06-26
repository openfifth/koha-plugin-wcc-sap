#!/usr/bin/perl

# Basic load test for the SAP plugin

use Modern::Perl;
use Test::More tests => 1;

BEGIN {
    use_ok('Koha::Plugin::Com::PTFSEurope::SAP');
}

diag("Testing Koha::Plugin::Com::PTFSEurope::SAP");