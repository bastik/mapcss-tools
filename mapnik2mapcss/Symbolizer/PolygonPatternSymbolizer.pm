package PolygonPatternSymbolizer;

use strict;
use warnings;

use Constants ();
use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub mapcss_properties {

    my ($self) = @_;
    
    my %prop = %{ $self->properties };
    my %mapcss = ();
    
    while (my ($key, $value) = each %prop) {
        
        if ($key eq 'file') 
        {
            $mapcss{'fill-image'} = '"' . Validate::file_path($value) . '"';
        }
        elsif ($key eq 'type')
        {
            # ignore: type should be clear from file name extension
        }
        elsif ($key eq 'width' or $key eq 'height')
        {
            # ignore: these are the dimension of the image file, so this is redundant information
        }
        else {
            die "unrecognized property for ".ref($self).": '$key'";
        }
    }
    return \%mapcss;
}

1;
