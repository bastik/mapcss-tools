package RuleProcessor;

use strict;
use warnings;

use Processor::Processor;

use base 'Processor';

# the entire rule can be manipulated by this processor

sub execute {
    my ($self, $layer) = @_;
    return unless ($layer->name eq $self->{_layername});

    print 'appying processor \'rule\' for layer '.$layer->name."\n" if $main::args_verbose;
    for my $style (@{ $layer->styles }) {
        for my $rule (@{ $style->rules }) {
            $self->proc->($rule);
        }
    }
}

1;
