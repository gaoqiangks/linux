#!/usr/bin/perl
use 5.010;
my @key=(
    "theorem",
    "lemma",
    "equation",
    "corollary",
    "example",
    "proposition",
    "definition",
    "remark",
    "align",
    "aligned",
    "split",
    "enumerate",
    "itemize",
);
foreach my $i(@key)
{
    my @k=split //, $i;
    my $s="";
    $s="\\\\?".$k[0].$k[1];
    foreach my $j(2..scalar @k-1)
    {
        $s.=$k[$j]."?";
    }
    my $luasnip1="s({trig=\"".$s."\", regTrig=true}, {";
    my $luasnip2="t({\"\\\\begin{$i}\",\"\\t\"}),i(1),t({\"\",\"\\\\end{$i}\"})";
    my $luasnip3="}),";
    say $luasnip1;
    say "\t".$luasnip2;
    say $luasnip3;
    $s.="\*";
    my $luasnip1="s({trig=\"".$s."\", regTrig=true}, {";
    my $luasnip2="t({\"\\\\begin{$i*}\",\"\\t\"}),i(1),t({\"\",\"\\\\end{$i*}\"})";
    say $luasnip1;
    say "\t".$luasnip2;
    say $luasnip3;
}
