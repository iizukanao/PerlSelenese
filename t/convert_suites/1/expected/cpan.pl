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
                                    browser_url => "http://www.cpan.org/" );

$sel->open_ok("/");
$sel->title_is("CPAN");
$sel->click_ok("link=Perl modules");
$sel->title_is("CPAN/modules");
$sel->click_ok("link=CPAN Search");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("The CPAN Search Site - search.cpan.org");
$sel->type_ok("query", "WWW::Mechanize");
$sel->click_ok("//input[\@value='CPAN Search']");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("The CPAN Search Site - search.cpan.org");
$sel->click_ok("//body[\@id='cpansearch']/h2[1]/a/b");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("WWW::Mechanize - search.cpan.org");
