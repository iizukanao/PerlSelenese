#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Selenium::Selenese::TestSuite qw/bulk_convert_suite/;

my $srcfile = shift or die "Usage: $0 <HTML test suite>\n";

my @outfiles = bulk_convert_suite($srcfile);
print "$_\n" for @outfiles;
