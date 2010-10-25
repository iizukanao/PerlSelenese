use lib '../lib';
use WWW::Selenium::Selenese::TestCase qw/case_to_perl/;

my $perl_code = case_to_perl('../t/convert_suites/1/TestCase1.html');
print $perl_code;
