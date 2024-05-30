package Koha::Plugin::Settings::settingsUpdate;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use Cwd qw(abs_path);

use C4::Context;

our $VERSION = '1.00';

our $metadata = {
    name            => 'Update Koha default settings',
    author          => 'Magnus Pettersson',
    date_authored   => '2024-05-19',
    date_updated    => "2025-05-19",
    minimum_version => '21.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin will update z3950 settings, Currency and date configs.',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my $self = shift;
}

sub uninstall {
    my $self = shift;
}

sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    if ( $cgi->param('update_z3950') ) {
        $self->update_z3950_servers();
    }
    elsif ( $cgi->param('add_currency') ) {
        $self->add_currency_to_database();
    }
    elsif ( $cgi->param('update_settings') ) {
        $self->update_koha_settings();
    }

    $self->tool_interface();
}

sub tool_interface {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'tool_interface.tt' });
   $self->output_html( $template->output() );
}

sub update_koha_settings {
    my $self = shift;

    C4::Context->set_preference( "CalendarFirstDayOfWeek", "1" );
    C4::Context->set_preference( "dateformat", "iso" );
    C4::Context->clear_syspref_cache();
}

sub add_currency_to_database {
    my $self = shift;
    my $dbh = C4::Context->dbh;

    my $check_sql = q{
        SELECT COUNT(*) FROM currency WHERE currency = 'SEK'
    };
    my $sth = $dbh->prepare($check_sql);
    $sth->execute();
    my ($count) = $sth->fetchrow_array();

    if ($count == 0) {
        my $insert_sql = q{
            INSERT INTO currency (currency, symbol, isocode, timestamp, rate, active, archived, p_sep_by_space)
            VALUES ('SEK', 'kr', 'SEK', '2024-05-22 17:11:32', 1.00000, 1, 0, NULL)
        };
        $sth = $dbh->prepare($insert_sql);
        $sth->execute();
    }
}

sub update_z3950_servers {
    my $self = shift;
    my $dbh = C4::Context->dbh;

    my $check_sql = q{
        SELECT COUNT(*) FROM z3950servers WHERE servername = 'LIBRIS'
    };
    my $sth = $dbh->prepare($check_sql);
    $sth->execute();
    my ($count) = $sth->fetchrow_array();

    if ($count == 0) {
        my $sth = $dbh->prepare("UPDATE z3950servers SET rank = 2, checked = NULL");
        $sth->execute();

        my $insert_sql = q{
            INSERT INTO z3950servers (id, host, port, db, userid, password, servername, checked, rank, syntax, timeout, servertype, encoding, recordtype, sru_options, sru_fields, add_xslt, attributes)
            VALUES (6, 'z3950.libris.kb.se', 210, 'libr', '', '', 'LIBRIS', 1, 1, 'UNIMARC', 0, 'zed', 'ISO_8859-1', 'biblio', '', '', '', '')
        };

        $sth = $dbh->prepare($insert_sql);
        $sth->execute();
    }
}

1;
