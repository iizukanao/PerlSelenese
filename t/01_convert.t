use Test::Base;
use FindBin;

plan tests => 2;

chdir("$FindBin::Bin/../");

opendir(DIR, 't/convert_cases');
my @dirs = grep { /^[^.]/ } readdir(DIR);
closedir(DIR);

my $tmpfile = 't/tmp_out.pl';

foreach my $dir (@dirs) {
    `./convert.pl t/convert_cases/$dir/in.html > $tmpfile`;
    open my $io, '<', $tmpfile or die $!;
    my $got = join('', <$io>);
    close $io;
    open $io, '<', "t/convert_cases/$dir/out.pl" or die $!;
    my $expected = join('', <$io>);
    close $io;
    is( $got, $expected, 'output precisely' );
}

unlink $tmpfile;
