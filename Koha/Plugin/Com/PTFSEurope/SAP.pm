package Koha::Plugin::Com::PTFSEurope::SAP;

use Modern::Perl;

use base            qw{ Koha::Plugins::Base };
use Koha::DateUtils qw(dt_from_string);
use Koha::File::Transports;
use Koha::Number::Price;

use File::Spec;
use List::Util qw(min max);
use Mojo::JSON qw{ decode_json };

our $VERSION  = '0.0.06';
our $metadata = {
    name => 'SAP Finance Integration',

    author          => 'PTFS Europe',
    date_authored   => '2024-11-15',
    date_updated    => '2024-11-15',
    minimum_version => '24.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     =>
      'A plugin to manage finance integration for WCC with SAP',
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
        my @days_of_week = qw(sunday monday tuesday wednesday thursday friday saturday);
        my $transport_days = {
            map { $days_of_week[$_] => 1 }
            grep { defined $days_of_week[$_] }
            split(',', $self->retrieve_data('transport_days'))
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
        my $days_str = join(',', sort { $a <=> $b } @selected_days);
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
    my %selected_days = map { $_ => 1 } @selected_days;

    # Get current day of the week (0=Sunday, ..., 6=Saturday)
    my $today = dt_from_string()->day_of_week % 7;
    return unless $selected_days{$today};

    my $output = $self->retrieve_data('output');
    my $transport;
    if ( $output eq 'upload' ) {
        $transport = Koha::File::Transports->find($self->retrieve_data('transport_server'));
        return unless $transport;
    }

    # Find start date (previous selected day) and end date (today)
    my $previous_day = max(grep { $_ < $today } @selected_days);  # Last selected before today
    $previous_day //= $selected_days[-1]; # Wrap around to last one from previous week

    # Calculate the start date (previous selected day) and end date (today)
    my $now = DateTime->now;
    my $start_date = $now->clone->subtract(days => ($today - $previous_day) % 7);
    my $end_date   = $now;

    my $report = $self->_generate_report($start_date, $end_date);
    my $filename = $self->_generate_filename();
    my $filepath = "IN/LB01/WK/" . $filename;

    if ( $output eq 'upload' ) {
        $transport->connect;
        open my $fh, '<', \$report;
        if ( $transport->upload_file($fh, $filepath) ) {
            close $fh;
            return 1;
        } else {
            # Deal with transport errors?
            close $fh;
            return 0;
        }
    } else {
        my $file_path = File::Spec->catfile($self->bundle_path, 'output', $filename);
        open(my $fh, '>', $file_path) or die "Unable to open $file_path: $!";
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

    my $startdate = $cgi->param('startdate') ? dt_from_string($cgi->param('startdate')) : undef;
    my $enddate   = $cgi->param('enddate') ? dt_from_string($cgi->param('enddate')) : undef;

    my $template = $self->get_template( { file => 'report-step1.tt' } );
    $template->param(
        startdate => $startdate,
        enddate   => $enddate,
    );

    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};
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

    my $results = $self->_generate_report($startdate, $enddate);

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
    );

    print $template->output();
}

sub _generate_report {
    my ( $self, $startdate, $enddate ) = @_;

    my $dbh   = C4::Context->dbh;
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
        { prefetch => [ 'booksellerid', 'aqorders' ] } );

    my $results       = "";
    my $invoice_count = 0;
    my $overall_total = 0;
    while ( my $invoice = $invoices->next ) {
        $invoice_count++;
        my $lines  = "";
        my $orders = $invoice->_result->aqorders;

        # Collect 'General Ledger lines'
        my $invoice_total = 0;
        my $tax_amount = 0;
        my $suppliernumber;
        my $costcenter;
        while ( my $line = $orders->next ) {
            my $unitprice = Koha::Number::Price->new( $line->unitprice_tax_included )->round * 100;
            $invoice_total = $invoice_total + $unitprice;
            my $tax_value_on_receiving = Koha::Number::Price->new( $line->tax_value_on_receiving )->round * 100;
            $tax_amount = $tax_amount + $tax_value_on_receiving;
            my $tax_rate_on_receiving = $line->tax_rate_on_receiving * 100;
            my $tax_code =
                $tax_rate_on_receiving == 20 ? 'P1'
              : $tax_rate_on_receiving == 5  ? 'P2'
              : $tax_rate_on_receiving == 0  ? 'P3'
              :                                '';
            $lines .= "\n" . "GL" . ","
              . $self->_map_fund_to_suppliernumber($line->budget->budget_code) . ","
              . $invoice->invoicenumber . ","
              . $unitprice . ","
              . ","
              . $tax_code . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . $self->_map_fund_to_costcenter($line->budget->budget_code) . ","
              . $invoice->invoicenumber . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ","
              . ",";

            $suppliernumber = $self->_map_fund_to_suppliernumber($line->budget->budget_code);
            $costcenter = $self->_map_fund_to_costcenter($line->budget->budget_code);
        }

        # Add 'Accounts Payable line'
        $invoice_total = $invoice_total * -1;
        $overall_total = $overall_total + $invoice_total;
        $results .= "\n" . "AP" . ","
          . $invoice->_result->booksellerid->accountnumber . ","
          . $invoice->invoicenumber . ","
          . ( $invoice->closedate =~ s/-//gr ) . ","
          . $invoice_total . ","
          . $tax_amount . ","
          . $invoice->invoicenumber . ","
          . ( $invoice->shipmentdate =~ s/-//gr ) . ","
          . $costcenter . ","
          . $suppliernumber . ","
          . ","
          . ","
          . $invoice->_result->booksellerid->invoiceprice->currency . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . ","
          . $invoice->_result->booksellerid->fax;
        $results .= $lines;
    }

    # Add 'Control Total line'
    $overall_total = $overall_total * -1;
    $results = "CT" . ","
      . $invoice_count . ","
      . $overall_total . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . ","
      . $results;

      return $results;
}

sub _generate_filename {
    my ($self, $args) = @_;

    my $filename = "WC_LB01_" . dt_from_string()->strftime('%Y%m%d%H%M%S');
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
        WYAD   => ''
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
        WYAD   => ''
    };
    my $return = defined( $map->{$fund} ) ? $map->{$fund} : "UNMAPPED:$fund";
    return $return;
}

1;
