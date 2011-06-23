package PolygonPatternSymbolizer;

use strict;
use warnings;

use Constants ();
use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'file') 
    {
        $self->set_property('fill-image', '"' . Validate::file_path($value) . '"');
    }
    else {
        die "unrecognized property for PolygonPatternSymbolizer: '$name'";
    }
}

1;
