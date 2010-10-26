#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;
use utf8;

my $sel = Test::WWW::Selenium->new( host => "localhost",
                                    port => 4444,
                                    browser => "*firefox",
                                    browser_url => "http://www.kernel.org/" );

$sel->open_ok("/");
$sel->title_is("The Linux Kernel Archives");
$sel->text_is("//h1", "The Linux Kernel Archives");
