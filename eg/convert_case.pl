#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Selenium::Selenese::TestCase qw/case_to_perl/;

my $srcfile = shift or die "Usage: $0 <HTML file>\n";

my $perl_code = case_to_perl($srcfile);
print $perl_code;
