#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Filter::FilterNormalizer;
use Filter::FilterCondition;
use Filter::Conjunction;

#our %debug = (filter => 1);

my $A = FilterCondition->new("A", "1", "=");
my $B = FilterCondition->new("B", "1", "=");
my $C = FilterCondition->new("C", "1", "=");
my $D = FilterCondition->new("D", "1", "=");
my $E = FilterCondition->new("E", "1", "=");
my $F = FilterCondition->new("F", "1", "=");
my $G = FilterCondition->new("G", "1", "=");
my $H = FilterCondition->new("H", "1", "=");
my $J = FilterCondition->new("J", "1", "=");

my @exps = (
    Conjunction->new([$A, Conjunction->new([$B, $C])]),
    Conjunction->new([$A, Disjunction->new([Disjunction->new([$B, $C]), $D])]),
    Conjunction->new([$A, Disjunction->new([$B, Conjunction->new([$C, $D])])]),
    Disjunction->new([Conjunction->new([$A, Disjunction->new([$B, $C])]), Conjunction->new([$D, $F])]),
    Conjunction->new([Disjunction->new([$A, $B]), $C, Conjunction->new([$D, Disjunction->new([$E, Conjunction->new([$F, $G]), $H])])]),
    Conjunction->new([Conjunction->new([$A, Conjunction->new([$B, $C])]),$D]),
);

for my $i (0...@exps - 1) {
    print "Expression ".($i+1).":\n";
    print $exps[$i]->toString . "\n";
    my $res = &FilterNormalizer::normalize_filter($exps[$i]);
    print $res->toString . "\n\n";
}
    
__END__

output:

Expression 1:
([A=1] && ([B=1] && [C=1]))
(D:([A=1] && [B=1] && [C=1]))

Expression 2:
([A=1] && (([B=1] || [C=1]) || [D=1]))
(([A=1] && [B=1]) || ([A=1] && [C=1]) || ([A=1] && [D=1]))

Expression 3:
([A=1] && ([B=1] || ([C=1] && [D=1])))
(([A=1] && [B=1]) || ([A=1] && [C=1] && [D=1]))

Expression 4:
(([A=1] && ([B=1] || [C=1])) || ([D=1] && [F=1]))
(([A=1] && [B=1]) || ([A=1] && [C=1]) || ([D=1] && [F=1]))

Expression 5:
(([A=1] || [B=1]) && [C=1] && ([D=1] && ([E=1] || ([F=1] && [G=1]) || [H=1])))
(([A=1] && [C=1] && [D=1] && [E=1]) || ([A=1] && [C=1] && [D=1] && [F=1] && [G=1]) || ([A=1] && [C=1] && [D=1] && [H=1]) || ([B=1] && [C=1] && [D=1] && [E=1]) || ([B=1] && [C=1] && [D=1] && [F=1] && [G=1]) || ([B=1] && [C=1] && [D=1] && [H=1]))

Expression 6:
(([A=1] && ([B=1] && [C=1])) && [D=1])
(D:([A=1] && [B=1] && [C=1] && [D=1]))



