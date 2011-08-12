package PolygonSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub mapcss_properties {

    my ($self) = @_;

    my %prop = %{ $self->properties };
    my %mapcss = ();

    while (my ($key, $value) = each %prop) {
        
        if ($key eq 'fill')
        {
            $mapcss{'fill-color'} = Validate::color($value);
        }
        elsif ($key eq 'fill-opacity')
        {
            Validate::nonnegativeFloat($value);
            die unless $value >= 0 && $value <= 1;
            $mapcss{'fill-opacity'} = $value;
        }
        elsif ($key eq 'gamma')
        {
            # gamma is not supported in mapcss - ignore for now
        }
        else {
            die "unrecognized property for ".ref($self).": '$key'";
        }
    }
    return \%mapcss;
}

1;
