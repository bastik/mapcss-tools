package FilterNormalizer;

use strict;
use warnings;

use Data::Dumper;

use Utils ();
use Filter::Conjunction ();
use Filter::Disjunction ();

# Main subroutine for filter normalization.
# Converts arbitrary logical expressions into a form, that can be used for MapCSS output.
sub normalize_filter {
    my $x = shift;
    $x = negation_normal_form($x);
    print "Normalized Negations:\n    ".$x->toString."\n" if $main::debug{filter};
    $x = disjunctive_normal_form($x);
    die unless is_in_disjunctive_normal_form($x);
    return $x;
}

# Convert logical expression to disjunctive normal form (see wikipedia).
# Basically this is the form
#   (A && B && C) || (D && E) || (F) || (G && H)
# where A, B, C, ... are simple filter conditions, possibly negated.
sub disjunctive_normal_form {
    my $x = shift;
    if ($x->isa('Conjunction'))
    # use distributive law to generate a Disjunction that is equivalent to the current expression
    {
        $x = flatten($x); # no conjunctions as operands should be left
        my @operands = @{ $x->operands };
        my $coll = [];
        
        my $collect_rec;
        $collect_rec = sub {
            my ($idx, $stack) = @_;
            print "Idx: $idx; Stack: ".Utils::toString($stack) . "\n" if $main::debug{filter};
            if ($idx == @operands) {
                print "Push!\n" if $main::debug{filter};
                my $stack_copy = [@{$stack}];
                push(@$coll, new Conjunction($stack_copy));
            } else {
                my $opd = $operands[$idx];
                if ($opd->isa('Disjunction')) 
                {
                    for my $o (@{ $opd->operands }) {
                        push(@$stack, $o);
                        $collect_rec->($idx + 1, $stack);
                        pop(@$stack);
                    }
                } 
                elsif ($opd->isa('FilterCondition')) 
                {
                    push(@$stack, $opd);
                    $collect_rec->($idx + 1, $stack);
                    pop(@$stack);
                }
                else 
                {
                    die;
                }
            }
        };
        
        $collect_rec->(0, []);
        $x = new Disjunction($coll);
        # continue with the case 'Disjuction'
    } 
    
    if ($x->isa('Disjunction'))
    {
        $x = flatten($x);
        my @operands = @{ $x->operands };
        my @coll = ();
        for my $opd (@{ $x->operands }) {
            if ($opd->isa('FilterCondition')) {
                push(@coll, new Conjunction([$opd]));
            } elsif ($opd->isa('Conjunction')) {
                unless (is_primitive_conjunction($opd)) {
                    $opd = disjunctive_normal_form($opd);
                }
                push(@coll, $opd);
            } else {
                die;
            }
        }
        return flatten(new Disjunction(\@coll));
    }
    elsif ($x->isa('FilterCondition')) 
    {
        return new Disjunction([new Conjunction([$x])]);
    } 
    else 
    {
        die;
    }
}

# Simplify expressions using associative property (only at top level of the expression).
# E.g. (A & (B & C)) => (A & B & C)
sub flatten($) {
    my $x = shift;
    if ($x->isa('Junction')) 
    {
        my $junction_type = ref($x); # Conjunction or Disjunction
        my $flatten_one_step = sub {
            my @operands = ();
            my $something_happened = 0;
            for my $o (@{ $x->operands }) {
                if ($o->isa($junction_type)) { 
                    # operand is of the same type, so flatten it
                    push(@operands, @{ $o->operands });
                    $something_happened = 1;
                } else {
                    push(@operands, $o);
                }
            }
            $x = $junction_type->new(\@operands);
            return $something_happened;
        };
        while ($flatten_one_step->()) {}
        return $x;
    } 
    else 
    {
        return $x;
    }
}

# Convert logical expression to negation normal form (see wikipedia).
#
# The goal of this subroutine is to get rid of negations at any outer level (Conjunction, Disjunction)
# and keep negations at the simple conditions, only.
#
# This subroutine modifies data in place. This means there should not be more than one reference to 
# a single condition or expression.
sub negation_normal_form($);
sub negation_normal_form($) {
    my $x = shift;
    if ($x->isa('Junction')) {
        my @operands = ();
        for my $o (@{ $x->operands }) {
            if ($x->negated) {
                $o->set_negated(!($o->negated));
            }
            push(@operands, negation_normal_form($o));
        }
        if ($x->isa('Disjunction')) {
            return $x->negated ? new Conjunction(\@operands) : new Disjunction(\@operands);
        } else {
            return $x->negated ? new Disjunction(\@operands) : new Conjunction(\@operands);
        }
    } elsif ($x->isa('FilterCondition')) {
        return $x;
    } else {
        die "unexpected input: '$x' (is a '".ref($x)."') Expected FilterCondition or Disjunction or Conjunction";
    }
}

# Is this a conjunction with only simple conditions as operands?
sub is_primitive_conjunction($) {
    my $x = shift;
    return 0 unless $x->isa('Conjunction');
    return 0 if $x->negated;
    for my $op (@{ $x->operands }) {
        return 0 unless $op->isa('FilterCondition');
    }
    return 1;
}

# Let's check if it is really in disjunctive normal form.
sub is_in_disjunctive_normal_form($) {
    my $x = shift;
    return 0 unless ($x->isa('Disjunction'));
    return 0 if $x->negated;
    for my $o (@{ $x->operands }) {
        return 0 unless is_primitive_conjunction($o);
    }
    return 1;
}

1;
