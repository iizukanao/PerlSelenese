#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Selenium::Selenese::TestSuite qw/bulk_convert_suite is_suite_file get_case_files/;
use File::Find;
use File::Spec;
use Getopt::Long ();

my $op_delete = 0;
Getopt::Long::Configure('bundling');
Getopt::Long::GetOptions(
    'd|delete' => \$op_delete,
);

my $srcdir = shift or die "Usage: $0 <dir>\n";

my $wanted = sub {
    return unless $_ =~ /\.html?$/i;
    my $is_suite = is_suite_file($_);
    if ($is_suite) {
        print "$File::Find::name\n";
        if ($op_delete) {
            my @outfiles = get_case_files($_);
            foreach my $outfile (@outfiles) {
                $outfile =~ s/\.html?/.pl/i;
                my $path = File::Spec->canonpath("$File::Find::dir/$outfile");
                print " delete $path\n";
                unlink $outfile;
            }
        } else {
            my @outfiles = bulk_convert_suite($_);
            foreach my $outfile (@outfiles) {
                my $path = File::Spec->canonpath("$File::Find::dir/$outfile");
                print " -> $path\n";
            }
        }
    }
};

find($wanted, $srcdir);
