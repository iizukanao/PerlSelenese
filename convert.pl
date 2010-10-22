#!/usr/bin/perl
# Selenium IDEで生成したHTMLを同等のPerlスクリプトに変換する

use strict;
use warnings;
use HTML::TreeBuilder;
use Text::MicroTemplate qw/:all/;
use FindBin;

# HTML上のコマンド名とPerlのメソッド名の対応表
my %command_map = (
    open => {  # HTMLでのコマンド名
        func => 'open_ok',  # Perlでのメソッド名
        args => 1,          # メソッドが取る引数の数
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

# base_urlを<link>から見つける
my $base_url;
foreach my $link ( $tree->find('link') ) {
    if ( $link->attr('rel') eq 'selenium.base' ) {
        $base_url = $link->attr('href');
    }
}

# <tbody>以下からコマンドを抽出
my $tbody = $tree->find('tbody');
my @sentences;
foreach my $tr ( $tbody->find('tr') ) {
    # 各<td>についてその下のHTMLを抽出する
    my @values = map {
        my $value = '';
        foreach my $child ( $_->content_list ) {
            # <br />が含まれる場合はタグごと抽出
            if ( ref($child) && eval{ $child->isa('HTML::Element') } ) {
                $value .= $child->as_HTML('<>&');
            } else {
                $value .= $child;
            }
        }
        $value;
    } $tr->find('td');

    # Perlスクリプトに変換
    my $sentence = convert_to_perl(\@values);
    push(@sentences, $sentence) if $sentence;
}
$tree = $tree->delete;

# テンプレートに渡すパラメータ
my @args = ( $base_url, \@sentences );

# test.mtをテンプレートとして読み込む
open my $io, '<', "$FindBin::Bin/test.mt" or die $!;
my $template = join '', <$io>;
close $io;
my $renderer = build_mt($template);
print $renderer->(@args)->as_string;

# 3つの値からなるコマンドをPerlスクリプトに変換して返す
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

# %command_mapの1エントリと引数を受け取り、Perlスクリプトに変換して返す
sub turn_func_into_perl {
    my ($code, @args) = @_;

    my $line = '';
    if ( ref($code->{func}) eq 'ARRAY' ) { # 複数のPerl文で構成される場合
        foreach my $subcode (@{ $code->{func} }) {
            $line .= "\n" if $line;
            $line .= turn_func_into_perl($subcode, @args);
        }
    } else { # 単一のPerl文で構成される場合
        if ( $code->{test} ) { # testパラメータがある場合はそれを関数として呼ぶ
            $line = $code->{test}.'($sel->'.$code->{func}.', '.(shift @args).');';
        } else { # $selオブジェクトのメソッドを呼ぶ
            $line = '$sel->'.$code->{func}.'(';
            if ( $code->{force_args} ) { # 引数が強制的に指定される場合
                $line .= join(', ', map { quote($_) } @{ $code->{force_args} });
            } else {
                if ( defined $code->{args} ) { # 引数の個数が指定されている場合
                    @args = map { defined $args[$_] ? $args[$_] : '' } (0..$code->{args}-1);
                }
                # 値の先頭の exact: を削除
                map { s/^exact:// } @args;
                # 引数をカンマで結合する
                $line .= join(', ', map { quote($_) } @args)
            }
            $line .= ');';
        }
        if ( $code->{repeat} ) { # 繰り返しがある場合は行を複製
            my @lines;
            push(@lines, $line) for (1..$code->{repeat});
            $line = join("\n", @lines);
        }
        if ( $code->{wait} ) { # WAIT構造を使用する場合
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

# エスケープした上でダブルクオーテーションで囲った文字列を返す
sub quote {
    my $str = shift;

    $str =~ s,<br />,\\n,g;
    $str =~ s/\Q$_\E/\\$_/g for qw(" % @ $);
    $str = '"'.$str.'"';
    return $str;
}
