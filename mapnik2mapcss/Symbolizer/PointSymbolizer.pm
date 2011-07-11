package PointSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'file') 
    {
        $self->set_property('icon-image', '"' . Validate::file_path($value) . '"');
    }
    elsif ($name eq 'allow_overlap') 
    {
        $self->set_property('allow_overlap', Validate::boolean($value));
    }
    else {
        die "unrecognized property for ".ref($self).": '$name'";
    }
}

1;
