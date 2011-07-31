package LayerProcessor;

use strict;
use warnings;

use Processor::Processor;

use base 'Processor';

# the entire rule can be manipulated by this processor

sub execute {
    my ($self, $layer) = @_;
    return unless ($layer->name eq $self->{_layername});

    print 'appying processor \'layer\' for layer '.$layer->name."\n" if $main::args_verbose;
    $self->proc->($layer);
}

1;
