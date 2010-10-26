use Test::Base;
use FindBin;
use WWW::Selenium::Selenese::TestCase qw/case_to_perl/;

plan tests => 2;

chdir("$FindBin::Bin/../");

opendir(DIR, 't/convert_cases');
my @dirs = grep { /^[^.]/ } readdir(DIR);
closedir(DIR);

my $tmpfile = 't/tmp_out.pl';

foreach my $dir (@dirs) {
    my $got = case_to_perl("t/convert_cases/$dir/in.html");
    open my $io, '<', "t/convert_cases/$dir/out.pl" or die $!;
    my $expected = join('', <$io>);
    close $io;
    is( $got, $expected, 'output precisely' );
}

unlink $tmpfile;
