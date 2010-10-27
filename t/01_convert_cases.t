use Test::Base;
use FindBin;
use WWW::Selenium::Selenese::TestCase qw/case_to_perl/;

plan tests => 2;

my $case_dir = "$FindBin::Bin/convert_cases";
opendir(DIR, $case_dir) or die $!;
my @dirs = grep { /^[^.]/ && -d "$case_dir/$_" } readdir(DIR);
closedir(DIR);

foreach my $dir (@dirs) {
    my $got = case_to_perl("$case_dir/$dir/in.html");
    open my $io, '<', "$case_dir/$dir/out.pl" or die $!;
    my $expected = join('', <$io>);
    close $io;
    is( $got, $expected, 'output precisely' );
}
