package WWW::Selenium::Selenese::TestSuite;

use strict;
use 5.008_001;
our $VERSION = '0.01';

require Exporter;
our @EXPORT_OK = qw(bulk_convert_suite);
*import = \&Exporter::import;

use Carp ();
use HTML::TreeBuilder;
use WWW::Selenium::Selenese::TestCase;
use File::Basename;

sub bulk_convert_suite {
    __PACKAGE__->new(shift)->bulk_convert;
}

sub bulk_convert {
    my $self = shift;

    my @outfiles;
    foreach my $case (@{ $self->{cases} }) {
        push(@outfiles, $case->convert_to_perl);
    }
    return @outfiles;
}

sub new {
    my ($class, $filename) = @_;
    my $self = bless {
        filename => $filename,
        cases    => undef,
    }, $class;

    $self->parse if $filename;

    $self;
}

sub parse {
    my $self = shift;
    my $suite_filename = $self->{filename};

    die "Can't read $suite_filename" unless -r $suite_filename;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($suite_filename);

    # base_urlを<link>から見つける
    my $base_url;
    foreach my $link ( $tree->find('link') ) {
        if ( $link->attr('rel') eq 'selenium.base' ) {
            $base_url = $link->attr('href');
        }
    }

    # <tbody>以下からコマンドを抽出
    my $tbody = $tree->find('tbody');
    my $base_dir = File::Basename::dirname( $self->{filename} );
    my @cases;
    if ($tbody) {
        foreach my $tr ( $tbody->find('tr') ) {
            my $link = $tr->find('td')->find('a');
            if ($link) {
                my $case;
                eval {
                    $case = WWW::Selenium::Selenese::TestCase->new(
                        $base_dir . '/' . $link->attr('href')
                    );
                };
                if ($@) {
                    warn "Can't read test case $base_dir/".$link->attr('href').": $!\n";
                }
                push(@cases, $case) if $case;
            }
        }
    }
    $tree = $tree->delete;

    $self->{cases} = \@cases;
}

1;
