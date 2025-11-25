package Koha::Plugin::Com::OpenFifth::SAP;

use Modern::Perl;

use base            qw{ Koha::Plugins::Base };
use C4::Context;
use Koha::DateUtils qw(dt_from_string);
use Koha::File::Transports;
use Koha::Number::Price;

use File::Spec;
use List::Util qw(min max);
use Mojo::JSON qw{ decode_json };
use Text::CSV;

our $VERSION = '0.0.31';

our $metadata = {
    name => 'SAP Finance Integration',

    author          => 'Open Fifth',
    date_authored   => '2024-11-15',
    date_updated    => '2025-11-25',
    minimum_version => '24.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description => 'A plugin to manage finance integration for WCC with SAP',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);
    $self->{cgi} = CGI->new();

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        my $available_transports = Koha::File::Transports->search();
        my @days_of_week =
          qw(sunday monday tuesday wednesday thursday friday saturday);
        my $transport_days = {
            map  { $days_of_week[$_] => 1 }
            grep { defined $days_of_week[$_] }
              split( ',', $self->retrieve_data('transport_days') )
        };
        $template->param(
            transport_server     => $self->retrieve_data('transport_server'),
            transport_days       => $transport_days,
            output               => $self->retrieve_data('output'),
            available_transports => $available_transports
        );

        $self->output_html( $template->output() );
    }
    else {
        # Get selected days (returns an array from multiple checkboxes)
        my @selected_days = $cgi->multi_param('days');
        my $days_str      = join( ',', sort { $a <=> $b } @selected_days );
        $self->store_data(
            {
                transport_server => scalar $cgi->param('transport_server'),
                transport_days   => $days_str,
                output           => scalar $cgi->param('output')
            }
        );
        $self->go_home();
    }
}

sub cronjob_nightly {
    my ($self) = @_;

    my $transport_days = $self->retrieve_data('transport_days');
    return unless $transport_days;

    my @selected_days = sort { $a <=> $b } split( /,/, $transport_days );
    my %selected_days = map  { $_ => 1 } @selected_days;

    # Get current day of the week (0=Sunday, ..., 6=Saturday)
    my $today = dt_from_string()->day_of_week % 7;
    return unless $selected_days{$today};

    my $output = $self->retrieve_data('output');
    my $transport;
    if ( $output eq 'upload' ) {
        $transport = Koha::File::Transports->find(
            $self->retrieve_data('transport_server') );
        return unless $transport;
    }

    # Find start date (previous selected day) and end date (today)
    my $previous_day =
      max( grep { $_ < $today } @selected_days );   # Last selected before today
    $previous_day //=
      $selected_days[-1];    # Wrap around to last one from previous week

    # Calculate the start date (previous selected day) and end date (today)
    my $now = DateTime->now;
    my $start_date =
      $now->clone->subtract( days => ( $today - $previous_day ) % 7 );
    my $end_date = $now;

    my $report = $self->_generate_report( $start_date, $end_date, 1 );
    return if !$report;
    my $filename = $self->_generate_filename();
    my $filepath = "IN/LB01/WK/" . $filename;

    if ( $output eq 'upload' ) {
        $transport->connect;
        open my $fh, '<', \$report;
        if ( $transport->upload_file( $fh, $filepath ) ) {
            close $fh;
            return 1;
        }
        else {
            # Deal with transport errors?
            close $fh;
            return 0;
        }
    }
    else {
        my $file_path =
          File::Spec->catfile( $self->bundle_path, 'output', $filename );
        open( my $fh, '>', $file_path ) or die "Unable to open $file_path: $!";
        print $fh $report;
        close($fh);
        return 1;
    }
}

sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('output') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $startdate =
      $cgi->param('startdate')
      ? dt_from_string( $cgi->param('startdate') )
      : undef;
    my $enddate =
      $cgi->param('enddate') ? dt_from_string( $cgi->param('enddate') ) : undef;

    my $template = $self->get_template( { file => 'report-step1.tt' } );
    $template->param(
        startdate => $startdate,
        enddate   => $enddate,
    );

    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;

    my $cgi       = $self->{'cgi'};
    my $startdate = $cgi->param('from');
    my $enddate   = $cgi->param('to');
    my $output    = $cgi->param('output');

    if ($startdate) {
        $startdate =~ s/^\s+//;
        $startdate =~ s/\s+$//;
        $startdate = eval { dt_from_string($startdate) };
    }

    if ($enddate) {
        $enddate =~ s/^\s+//;
        $enddate =~ s/\s+$//;
        $enddate = eval { dt_from_string($enddate) };
    }

    my $results = $self->_generate_report( $startdate, $enddate );

    my $templatefile;
    if ( $output eq "txt" ) {
        my $filename = $self->_generate_filename;
        print $cgi->header( -attachment => "$filename" );
        $templatefile = 'report-step2-txt.tt';
    }
    else {
        print $cgi->header();
        $templatefile = 'report-step2-html.tt';
    }

    my $template = $self->get_template( { file => $templatefile } );

    $template->param(
        date_ran  => dt_from_string(),
        startdate => dt_from_string($startdate),
        enddate   => dt_from_string($enddate),
        results   => $results,
        filename  => $self->_generate_filename(),
        output_config => $self->retrieve_data('output'),
        CLASS     => ref($self),
    );

    print $template->output();
}

sub sftp_upload {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $startdate = $cgi->param('from');
    my $enddate   = $cgi->param('to');

    # Parse dates
    if ($startdate) {
        $startdate =~ s/^\s+//;
        $startdate =~ s/\s+$//;
        $startdate = eval { dt_from_string($startdate) };
    }

    if ($enddate) {
        $enddate =~ s/^\s+//;
        $enddate =~ s/\s+$//;
        $enddate = eval { dt_from_string($enddate) };
    }

    # Check output configuration - if set to upload, use transport
    my $output = $self->retrieve_data('output');
    
    if ($output eq 'upload') {
        # Get transport configuration
        my $transport = Koha::File::Transports->find( $self->retrieve_data('transport_server') );

        unless ($transport) {
            print $cgi->header('application/json');
            print '{"success": false, "message": "No SFTP transport configured"}';
            return;
        }

        # Generate report
        my $filename = $self->_generate_filename();
        my $filepath = "IN/LB01/WK/" . $filename;
        my $report = $self->_generate_report( $startdate, $enddate );

        unless ($report) {
            print $cgi->header('application/json');
            print '{"success": false, "message": "Failed to generate report"}';
            return;
        }

        # Upload to SFTP
        eval {
            $transport->connect;
            open my $fh, '<', \$report;
            my $upload_result = $transport->upload_file( $fh, $filepath );
            close $fh;

            if ($upload_result) {
                print $cgi->header('application/json');
                print '{"success": true, "message": "File uploaded successfully to SFTP server", "filename": "' . $filename . '"}';
            } else {
                print $cgi->header('application/json');
                print '{"success": false, "message": "Failed to upload file to SFTP server"}';
            }
        };

        if ($@) {
            print $cgi->header('application/json');
            print '{"success": false, "message": "SFTP upload error: ' . $@ . '"}';
        }
    } else {
        # Save to local file
        my $filename = $self->_generate_filename();
        my $report = $self->_generate_report( $startdate, $enddate );
        
        unless ($report) {
            print $cgi->header('application/json');
            print '{"success": false, "message": "Failed to generate report"}';
            return;
        }
        
        my $file_path = File::Spec->catfile( $self->bundle_path, 'output', $filename );
        eval {
            open( my $fh, '>', $file_path ) or die "Unable to open $file_path: $!";
            print $fh $report;
            close($fh);
            
            print $cgi->header('application/json');
            print '{"success": true, "message": "File saved successfully to server", "filename": "' . $filename . '"}';
        };
        
        if ($@) {
            print $cgi->header('application/json');
            print '{"success": false, "message": "Error saving file: ' . $@ . '"}';
        }
    }
}

sub _generate_report {
    my ( $self, $startdate, $enddate, $cron ) = @_;

    my $where = { 'booksellerid.name' => { 'LIKE' => 'WCC%' } };

    my $dtf           = Koha::Database->new->schema->storage->datetime_parser;
    my $startdate_iso = $dtf->format_date($startdate);
    my $enddate_iso   = $dtf->format_date($enddate);
    if ( $startdate_iso && $enddate_iso ) {
        $where->{'me.closedate'} =
          [ -and => { '>=', $startdate_iso }, { '<=', $enddate_iso } ];
    }
    elsif ($startdate_iso) {
        $where->{'me.closedate'} = { '>=', $startdate_iso };
    }
    elsif ($enddate_iso) {
        $where->{'me.closedate'} = { '<=', $enddate_iso };
    }

    my $invoices = Koha::Acquisition::Invoices->search( $where,
        { prefetch => [ 'booksellerid', 'aqorders', 'aqinvoice_adjustments' ] } );

    return 0 if $invoices->count == 0 && $cron;

    # Initialize Text::CSV for proper CSV formatting
    my $csv = Text::CSV->new({
        binary => 1,
        eol => "\015\012",
        sep_char => ",",
        quote_char => '"',
        always_quote => 0
    });

    my $results = "";
    open my $fh, '>', \$results or die "Could not open scalar ref: $!";

    my $invoice_count = 0;
    my $overall_total = 0;
    my @all_rows = ();  # Store all rows to add CT row at the beginning
    while ( my $invoice = $invoices->next ) {
        $invoice_count++;
        my $lines  = "";
        my $orders = $invoice->_result->aqorders;
        my @invoice_gl_rows = ();  # Temporary array for GL rows of this invoice

        # Collect and categorize adjustments first
        my $adjustments = $invoice->_result->aqinvoice_adjustments;
        my $total_adjustments = 0;
        my @general_adjustments = ();    # Adjustments without order references
        my %order_adjustments = ();      # Adjustments with order numbers, keyed by ordernumber
        
        while ( my $adjustment = $adjustments->next ) {
            # Keep full precision - don't round yet (Round Last principle)
            my $adjustment_amount = $adjustment->adjustment;

            # For AP total, we always need tax-included amounts
            # Parse tax rate from adjustment note to calculate tax-included amount
            my $note = $adjustment->note || '';
            my $tax_rate_pct = 0;
            if ( $note =~ /Tax Rate: (\d+)%/ ) {
                $tax_rate_pct = $1;
            }

            my $adjustment_amount_inc = $adjustment_amount;
            if ( !C4::Context->preference('CalculateFundValuesIncludingTax') && $tax_rate_pct > 0 ) {
                # Adjustment is tax-excluded, add tax to get tax-included for AP total
                $adjustment_amount_inc = $adjustment_amount * ( 1 + ( $tax_rate_pct / 100 ) );
            }

            # Convert to pence for total calculation (still full precision)
            $total_adjustments += $adjustment_amount_inc * 100;

            # Determine which order this adjustment applies to from the note field
            my $adjustment_note = $adjustment->note || '';
            my $adjustment_ordernumber = '';
            if ($adjustment_note =~ /Order #(\d+)/) {
                $adjustment_ordernumber = $1;
                # Store adjustment for later insertion after the corresponding order
                push @{$order_adjustments{$adjustment_ordernumber}}, $adjustment;
            } else {
                # Store general adjustment for insertion at the top
                push @general_adjustments, $adjustment;
            }
        }

        # Helper function to generate adjustment GL row
        my $generate_adjustment_row = sub {
            my ($adjustment, $gl_sum_ref, $tax_sum_ref) = @_;
            # Keep full precision - don't round yet (Round Last principle)
            my $adjustment_amount = $adjustment->adjustment;

            # Parse tax rate from adjustment note
            my $note = $adjustment->note || '';
            my $tax_rate_pct = 0;
            if ( $note =~ /Tax Rate: (\d+)%/ ) {
                $tax_rate_pct = $1;
            }

            # Determine tax code based on tax rate
            my $tax_code =
                $tax_rate_pct == 20 ? 'P1'
              : $tax_rate_pct == 5  ? 'P2'
              : $tax_rate_pct == 0  ? 'P3'
              :                       'P3';  # Default to P3 if unknown

            # Calculate tax-exclusive amount and tax value
            my $adjustment_amount_excl = $adjustment_amount;
            my $adjustment_tax_value = 0;
            if ( C4::Context->preference('CalculateFundValuesIncludingTax') && $tax_rate_pct > 0 ) {
                # Adjustment is tax-included, back-calculate to get tax-exclusive and tax value
                $adjustment_amount_excl = $adjustment_amount / ( 1 + ( $tax_rate_pct / 100 ) );
                $adjustment_tax_value = $adjustment_amount - $adjustment_amount_excl;
            }

            # Round to nearest penny, then convert to integer pence (Round Last - only at output)
            # Use HMRC-compliant rounding (round half up)
            $adjustment_amount_excl =
              Koha::Number::Price->new($adjustment_amount_excl)->round * 100;

            # Skip £0 adjustments - SAP/Basware doesn't allow 0 values on GL lines (ticket 149681)
            return if $adjustment_amount_excl == 0;

            # Add to GL sum for accurate AP calculation
            $$gl_sum_ref += $adjustment_amount_excl;

            # Add tax value to tax sum (in pence, full precision)
            $$tax_sum_ref += $adjustment_tax_value * 100;

            # Use the adjustment's budget if available, otherwise fallback to first order's budget
            my $adj_budget_code;
            if ($adjustment->budget_id) {
                my $adj_fund = Koha::Acquisition::Funds->find($adjustment->budget_id);
                $adj_budget_code = $adj_fund ? $adj_fund->budget_code : '';
            } elsif ($orders->count > 0) {
                $orders->reset;  # Reset iterator to access first element
                $adj_budget_code = $orders->first->budget->budget_code;
            } else {
                $adj_budget_code = '';  # No budget info available
            }

            return [
                "GL",                                                  # 1
                $self->_map_fund_to_suppliernumber($adj_budget_code),  # 2
                $invoice->invoicenumber,                               # 3
                $adjustment_amount_excl,                               # 4
                "",                                                    # 5
                $tax_code,                                             # 6
                "", "", "", "", "",                                    # 7-11
                $self->_map_fund_to_costcenter($adj_budget_code),      # 12
                $invoice->invoicenumber,                               # 13
                "", "", "", "", "", "", "", "", "", "", "", ""         # 14-25
            ];
        };

        # Track sum of rounded GL values for accurate AP calculation
        my $gl_sum_rounded = 0;
        # Track tax amount (including from adjustments)
        my $tax_amount = 0;

        # Add general adjustments (no line ID) at the top
        for my $adjustment (@general_adjustments) {
            my $gl_row = $generate_adjustment_row->($adjustment, \$gl_sum_rounded, \$tax_amount);
            push @invoice_gl_rows, $gl_row if $gl_row;
        }

        # Collect 'General Ledger lines' for orders, interleaving order-specific adjustments
        my $suppliernumber;
        my $costcenter;
        while ( my $line = $orders->next ) {
            # Keep full precision - don't round yet (Round Last principle)
            # Values in pence but still full precision
            my $unitprice_tax_excluded = $line->unitprice_tax_excluded * 100;
            my $quantity = $line->quantity || 1;
            my $tax_value_on_receiving = $line->tax_value_on_receiving * 100;
            $tax_amount = $tax_amount + $tax_value_on_receiving;
            my $tax_rate_on_receiving = $line->tax_rate_on_receiving * 100;
            my $tax_code =
                $tax_rate_on_receiving == 20 ? 'P1'
              : $tax_rate_on_receiving == 5  ? 'P2'
              : $tax_rate_on_receiving == 0  ? 'P3'
              :                                '';

            # Generate one GL row per quantity unit
            for my $qty_unit (1..$quantity) {
                # Round each GL line value and add to sum
                my $rounded_gl_value = Koha::Number::Price->new($unitprice_tax_excluded / 100)->round * 100;
                $gl_sum_rounded += $rounded_gl_value;

                push @invoice_gl_rows, [
                    "GL",                                                           # 1
                    $self->_map_fund_to_suppliernumber($line->budget->budget_code), # 2
                    $invoice->invoicenumber,                                        # 3
                    $rounded_gl_value,                                              # 4 - HMRC round (Round Last)
                    "",                                                             # 5
                    $tax_code,                                                      # 6
                    "", "", "", "", "",                                             # 7-11
                    $self->_map_fund_to_costcenter($line->budget->budget_code),     # 12
                    $invoice->invoicenumber,                                        # 13
                    "", "", "", "", "", "", "", "", "", "", "", ""                  # 14-25
                ];
            }

            # Add any adjustments that reference this order
            my $current_ordernumber = $line->ordernumber;
            if (exists $order_adjustments{$current_ordernumber}) {
                for my $adjustment (@{$order_adjustments{$current_ordernumber}}) {
                    my $gl_row = $generate_adjustment_row->($adjustment, \$gl_sum_rounded, \$tax_amount);
                    push @invoice_gl_rows, $gl_row if $gl_row;
                }
                # Remove processed adjustments to avoid duplicates
                delete $order_adjustments{$current_ordernumber};
            }

            $suppliernumber = $self->_map_fund_to_suppliernumber($line->budget->budget_code);
            $costcenter = $self->_map_fund_to_costcenter($line->budget->budget_code);
        }

        # Calculate invoice total from sum of rounded GL values and rounded tax
        # This ensures AP total = -(GL sum + Tax)
        my $tax_amount_rounded = Koha::Number::Price->new($tax_amount / 100)->round * 100;
        my $invoice_total = $gl_sum_rounded + $tax_amount_rounded;

        # Add 'Accounts Payable row' BEFORE GL rows (required by Basware)
        $invoice_total = $invoice_total * -1;
        $overall_total = $overall_total + $invoice_total;

        push @all_rows, [
            "AP",                                                   # 1
            $invoice->_result->booksellerid->accountnumber,         # 2
            $invoice->invoicenumber,                               # 3
            ($invoice->closedate =~ s/-//gr),                      # 4
            $invoice_total,                                        # 5 - Already in integer pence (from rounded GL sum)
            $tax_amount_rounded,                                   # 6 - Already in integer pence (rounded)
            $invoice->invoicenumber,                               # 7
            ($invoice->shipmentdate =~ s/-//gr),                   # 8
            $costcenter,                                           # 9
            $suppliernumber,                                       # 10
            "", "",                                               # 11-12
            $invoice->_result->booksellerid->invoiceprice->currency, # 13
            "", "", "", "", "", "", "", "", "", "", "",         # 14-24
            $invoice->_result->booksellerid->fax                   # 25
        ];

        # Now add all GL rows for this invoice after the AP row
        push @all_rows, @invoice_gl_rows;
    }

    # Add 'Control Total row' at the beginning
    $overall_total = $overall_total * -1;
    my $ct_row = [
        "CT",                                       # 1
        $invoice_count,                             # 2
        $overall_total,                             # 3 - Already in integer pence (sum of rounded AP totals)
        "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" # 4-25
    ];
    
    # Print Control Total first, then all other rows
    $csv->print($fh, $ct_row);
    for my $row (@all_rows) {
        $csv->print($fh, $row);
    }
    
    close $fh;
    return $results;
}

sub _generate_filename {
    my ( $self, $args ) = @_;

    my $filename  = "WC_LB01_" . dt_from_string()->strftime('%Y%m%d%H%M%S');
    my $extension = ".txt";

    return $filename . $extension;
}

sub _map_fund_to_costcenter {
    my ( $self, $fund ) = @_;
    my $map = {
        WAFI   => "W26315",
        WANF   => "W26315",
        WARC   => "W26311",
        WBAS   => "W26315",
        WCFI   => "W26315",
        WCHG   => "W26315",
        WCHI   => "W26315",
        WCNF   => "W26315",
        WCOM   => "W26315",
        WEBE   => "W26315",
        WELE   => "W26315",
        WERE   => "W26353",
        WFSO   => "W26315",
        WHLS   => "W26352",
        WLPR   => "W26315",
        WNHC   => "W26315",
        WNSO   => "W26315",
        WPER   => "W26315",
        WRCHI  => "W26315",
        WREF   => "W26353",
        WREFSO => "W26315",
        WREP   => "W26315",
        WREQ   => "W26315",
        WRFI   => "W26315",
        WRNF   => "W26315",
        WSHC   => "W26353",
        WSPO   => "W26315",
        WSSS   => "W26315",
        WVAT   => "W26315",
        WWML   => "W26352",
        WYAD   => "W26315"
    };
    my $return = defined( $map->{$fund} ) ? $map->{$fund} : "UNMAPPED:$fund";
    return $return;
}

sub _map_fund_to_suppliernumber {
    my ( $self, $fund ) = @_;
    my $map = {
        WAFI   => 4539,
        WANF   => 4539,
        WARC   => 4539,
        WBAS   => 4539,
        WCFI   => 4539,
        WCHG   => 4539,
        WCHI   => 4539,
        WCNF   => 4539,
        WCOM   => 4539,
        WEBE   => 4539,
        WELE   => 4539,
        WERE   => 5190,
        WFSO   => 4539,
        WHLS   => 4539,
        WLPR   => 4539,
        WNHC   => 4539,
        WNSO   => 4539,
        WPER   => 4625,
        WRCHI  => 4539,
        WREF   => 4539,
        WREFSO => 4539,
        WREP   => 4539,
        WREQ   => 4539,
        WRFI   => 4539,
        WRNF   => 4539,
        WSHC   => 4539,
        WSPO   => 4539,
        WSSS   => 4539,
        WVAT   => 4539,
        WWML   => 4539,
        WYAD   => 4539
    };
    my $return = defined( $map->{$fund} ) ? $map->{$fund} : "UNMAPPED:$fund";
    return $return;
}

1;
