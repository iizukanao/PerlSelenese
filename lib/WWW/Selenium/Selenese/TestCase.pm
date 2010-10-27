package WWW::Selenium::Selenese::TestCase;

use strict;
use 5.008_001;
our $VERSION = '0.01';

require Exporter;
our @EXPORT_OK = qw(case_to_perl);
*import = \&Exporter::import;

use Carp ();
use HTML::TreeBuilder;
use WWW::Selenium::Selenese::TestCase;
use WWW::Selenium::Selenese::Command;
use Text::MicroTemplate;
use File::Basename;

sub case_to_perl {
    __PACKAGE__->new(shift)->as_perl;
}

sub new {
    my ($class, $filename) = @_;
    my $self = bless {
        filename => $filename,
        base_url => undef,
        commands => undef,
    }, $class;

    $self->parse if $filename;

    $self;
}

sub parse {
    my $self = shift;
    my $filename = $self->{filename} or die "specify a filename";

    die "Can't read $filename" unless -r $filename;

    return if $self->{commands};

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

    # base_urlを<link>から見つける
    foreach my $link ( $tree->find('link') ) {
        if ( $link->attr('rel') eq 'selenium.base' ) {
            $self->{base_url} = $link->attr('href');
        }
    }

    # <tbody>以下からコマンドを抽出
    my $tbody = $tree->find('tbody');
    my @commands;
    foreach my $tr ( $tbody->find('tr') ) {
        # 各<td>についてその下のHTMLを抽出する
        my @values = map {
            my $value = '';
            foreach my $child ( $_->content_list ) {
                # <br />が含まれる場合はタグごと抽出
                if ( ref($child) && eval{ $child->isa('HTML::Element') } ) {
                    $value .= $child->as_HTML('<>&');
                } else {
                    $value .= $child;
                }
            }
            $value;
        } $tr->find('td');

        # Perlスクリプトに変換
        my $command = WWW::Selenium::Selenese::Command->new(\@values);
        push(@commands, $command);
    }
    $self->{commands} = \@commands;
    $tree = $tree->delete;
}

sub as_perl {
    my $self = shift;

    my $perl_code = '';
    foreach my $command (@{ $self->{commands} }) {
        my $code = $command->as_perl;
        $perl_code .= $code if defined $code;
    }
    chomp $perl_code;

    # テンプレートに渡すパラメータ
    my @args = ( $self->{base_url}, Text::MicroTemplate::encoded_string($perl_code) );

    # test.mtをテンプレートとして読み込む
    open my $io, '<', File::Basename::dirname(__FILE__)."/test.mt" or die $!;
    my $template = join '', <$io>;
    close $io;
    my $renderer = Text::MicroTemplate::build_mt($template);
    return $renderer->(@args)->as_string;
}

sub convert_to_perl {
    my $self = shift;

    my $outfile = $self->{filename};
    $outfile =~ s/\.html?$/.pl/;

    my $perl = $self->as_perl;

    open my $io, '>', $outfile or die $!;
    print $io $perl;
    close $io;

    return $outfile;
}

1;
