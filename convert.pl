#!/usr/bin/perl
# Selenium IDEで生成したHTMLを同等のPerlスクリプトに変換する

use strict;
use warnings;
use HTML::TreeBuilder;
use Text::MicroTemplate qw/:all/;

my %command_map = (
    open => {
        func => 'open_ok',
        args => 1,
    },
    assertTitle => {
        func => 'title_is',
        args => 1,
    },
    verifyTitle => {
        func => 'title_is',
        args => 1,
    },
    type => {
        func => 'type_ok',
        args => 2,
    },
    click => {
        func => 'click_ok',
        args => 1,
    },
    select => {
        func => 'select_ok',
        args => 2,
    },
    clickAndWait => {
        func => [
            {
                func => 'click_ok',
                args => 1,
            },
            {
                func => 'wait_for_page_to_load_ok',
                force_args => [ 30000 ],
            },
        ],
    },
    waitForPageToLoad => {
        func   => 'wait_for_page_to_load_ok',
        args => 1,
    },
    verifyTextPresent => {
        func => 'is_text_present_ok',
        args => 1,
    },
    assertTextPresent => {
        func => 'is_text_present_ok',
        args => 1,
    },
    assertElementPresent => {
        func => 'is_element_present_ok',
        args => 1,
    },
    verifyElementPresent => {
        func => 'is_element_present_ok',
        args => 1,
    },
    verifyText => {
        func => 'text_is',
        args => 2,
    },
    assertText => {
        func => 'text_is',
        args => 2,
    },
    waitForElementPresent => {
        wait => 1,
        func => 'is_element_present',
        args => 1,
    },
    waitForTextPresent => {
        wait => 1,
        func => 'is_text_present',
        args => 1,
    },
);

my $filename = shift or die "Usage: $0 <filename>\n";

my $tree = HTML::TreeBuilder->new;
$tree->parse_file($filename);
my $base_url;
foreach my $link ( $tree->find('link') ) {
    if ( $link->attr('rel') eq 'selenium.base' ) {
        $base_url = $link->attr('href');
    }
}

my $tbody = $tree->find('tbody');
my @sentences;
foreach my $tr ( $tbody->find('tr') ) {
    my @values = map {
        my $value = '';
        foreach my $child ( $_->content_list ) {
            if ( ref($child) && eval{ $child->isa('HTML::Element') } ) {
                $value .= $child->as_HTML('<>&');
            } else {
                $value .= $child;
            }
        }
        $value;
    } $tr->find('td');
    my $sentence = convert_to_perl(\@values);
    push(@sentences, $sentence) if $sentence;
}
$tree = $tree->delete;

my @args = ( $base_url, \@sentences );

open my $io, '<', 'test.mt' or die $!;
my $template = join '', <$io>;
close $io;
my $renderer = build_mt($template);
print $renderer->(@args)->as_string;

sub convert_to_perl {
    my ($values) = @_;

    my $line;
    my $code = $command_map{ $values->[0] };
    my @args = @$values;
    shift @args;
    if ($code) {
        $line .= turn_func_into_perl($code, @args);
    }
    if ($line) {
        return Text::MicroTemplate::encoded_string($line);
    } else {
        return undef;
    }
}

sub turn_func_into_perl {
    my ($code, @args) = @_;

    my $line = '';
    if ( ref($code->{func}) eq 'ARRAY' ) {
        foreach my $subcode (@{ $code->{func} }) {
            $line .= "\n" if $line;
            $line .= turn_func_into_perl($subcode, @args);
        }
    } else {
        if ( $code->{test} ) {
            $line = $code->{test}.'($sel->'.$code->{func}.', '.(shift @args).');';
        } else {
            $line = '$sel->'.$code->{func}.'(';
            if ( $code->{force_args} ) {
                $line .= join(', ', map { quote($_) } @{ $code->{force_args} });
            } else {
                if ( defined $code->{args} ) {
                    @args = map { defined $args[$_] ? $args[$_] : '' } (0..$code->{args}-1);
                }
                map { s/^exact:// } @args;
                $line .= join(', ', map { quote($_) } @args)
            }
            $line .= ');';
        }
        if ( $code->{repeat} ) {
            my @lines;
            push(@lines, $line) for (1..$code->{repeat});
            $line = join("\n", @lines);
        }
        if ( $code->{wait} ) {
            $line =~ s/;$//;
            $line = <<EOF;
WAIT: {
    for (1..60) {
        if (eval { $line }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}
EOF
            chomp $line;
        }
    }
    return $line;
}

sub quote {
    my $str = shift;

    $str =~ s,<br />,\\n,g;
    $str =~ s/\Q$_\E/\\$_/g for qw(" % @ $);
    $str = '"'.$str.'"';
    return $str;
}
