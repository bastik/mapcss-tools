package LineSymbolizer;

use strict;
use warnings;

use Constants ();
use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    # default values
    $self->set_property('width', '1');
    $self->set_property('color', 'black');
    return $self;
}

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'stroke') 
    {
        $self->set_property('color', Validate::color($value));
    }
    elsif ($name eq 'stroke-width') 
    {
        $self->set_property('width', Validate::positiveFloat($value));
    }
    elsif ($name eq 'stroke-linejoin') 
    {
        die "Unknown linejoin value: '$value'" unless Constants::LINEJOIN_TYPES->{$value};
        $self->set_property('linejoin', Constants::LINEJOIN_TYPES->{$value});
    }
    elsif ($name eq 'stroke-linecap') 
    {
        die unless Constants::LINECAP_TYPES->{$value};
        $self->set_property('linecap', Constants::LINECAP_TYPES->{$value});
    }
    elsif ($name eq 'stroke-dasharray') 
    {
        $self->set_property('dashes', Validate::dashes($value));
    }
    elsif ($name eq 'stroke-opacity') 
    {
        Validate::nonnegativeFloat($value);
        die unless $value >= 0 && $value <= 1;
        $self->set_property('opacity', $value);
    }
    else {
        die "unrecognized property for LineSymbolizer: '$name'";
    }
}

1;
