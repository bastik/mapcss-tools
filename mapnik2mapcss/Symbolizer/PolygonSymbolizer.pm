package PolygonSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'fill')
    {
        $self->{_properties}->{'fill-color'} = Validate::color($value);
    }
    elsif ($name eq 'fill-opacity')
    {
        Validate::nonnegativeFloat($value);
        die unless $value >= 0 && $value <= 1;
        $self->{_properties}->{'fill-opacity'} = $value;
    }
    elsif ($name eq 'gamma')
    {
        # gamma is not supported in mapcss - ignore for now
    }
    else {
        die "unrecognized property for PolygonSymbolizer: '$name'";
    }
}

1;
