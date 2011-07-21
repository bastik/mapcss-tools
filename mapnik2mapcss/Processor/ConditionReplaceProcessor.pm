package ConditionReplaceProcessor;

use strict;
use warnings;

use Processor::Processor;

use base 'Processor';

# processor that can be used to replace individual conditions by another conditional expression

sub execute {
    my ($self, $layer) = @_;
    return unless ($layer->name eq $self->{_layername});

    print 'appying "condition-replace" processor for layer '.$layer->name."\n" if $main::args_verbose;
    for my $style (@{ $layer->styles }) {
        for my $rule (@{ $style->rules }) {
            my $filter = $rule->filter;
            my $process_rec;
            $process_rec = sub {
                my $e = shift;
                if ($e->isa('FilterCondition')) 
                {
                    return $self->proc->($e);
                } 
                elsif ($e->isa('Junction')) 
                {
                    my @operands = @{ $e->operands };
                    for (my $i=0; $i < @operands; ++$i) {
                        $operands[$i] = $process_rec->($operands[$i]);
                    }
                    $e->set_operands(\@operands);
                    return $e;
                }
                else
                {
                    die;
                }
            };
            $rule->set_filter($process_rec->($filter));
        }
    }
}

1;
