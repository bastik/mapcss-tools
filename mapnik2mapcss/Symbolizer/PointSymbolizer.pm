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
    elsif ($name eq 'type')
    {
        # ignore: type should be clear from file name extension
    }
    elsif ($name eq 'width' or $name eq 'height')
    {
        # ignore: these are the dimension of the image file, so this is redundant information
    }
    else {
        die "unrecognized property for ".ref($self).": '$name'";
    }
}

1;
