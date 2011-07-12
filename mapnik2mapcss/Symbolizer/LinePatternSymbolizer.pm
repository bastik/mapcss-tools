package LinePatternSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    return $self;
}

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'file') 
    {
        $self->set_property('pattern-image', '"' . Validate::file_path($value) . '"');
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
