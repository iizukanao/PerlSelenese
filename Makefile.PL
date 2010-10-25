use inc::Module::Install;
name 'WWW-Selenium-Selenese';
all_from 'lib/WWW/Selenium/Selenese.pm';

requires 'HTML::TreeBuilder';
requires 'Text::MicroTemplate';
requires 'Time::HiRes';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
