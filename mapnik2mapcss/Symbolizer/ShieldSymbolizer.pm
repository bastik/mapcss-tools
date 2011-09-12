package ShieldSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub mapcss_properties {

    my ($self) = @_;

    my %prop = %{ $self->properties };
    my %mapcss = ();

    # TODO
    
    return \%mapcss;
}

1;
