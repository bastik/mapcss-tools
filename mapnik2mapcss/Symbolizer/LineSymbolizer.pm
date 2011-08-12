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
    $self->set_property('stroke-width', '1');
    $self->set_property('stroke', 'black');
    return $self;
}

sub mapcss_properties {

    my ($self) = @_;

    my %prop = %{ $self->properties };
    my %mapcss = ();

    while (my ($key, $value) = each %prop) {
        if ($key eq 'stroke') 
        {
            $mapcss{'color'} = Validate::color($value);
        }
        elsif ($key eq 'stroke-width') 
        {
            $mapcss{'width'} = Validate::positiveFloat($value);
        }
        elsif ($key eq 'stroke-linejoin') 
        {
            die "Unknown linejoin value: '$value'" unless Constants::LINEJOIN_TYPES->{$value};
            $mapcss{'linejoin'} = Constants::LINEJOIN_TYPES->{$value};
        }
        elsif ($key eq 'stroke-linecap') 
        {
            die unless Constants::LINECAP_TYPES->{$value};
            $mapcss{'linecap'} = Constants::LINECAP_TYPES->{$value};
        }
        elsif ($key eq 'stroke-dasharray') 
        {
            $mapcss{'dashes'} = Validate::dashes($value);
        }
        elsif ($key eq 'stroke-opacity') 
        {
            Validate::nonnegativeFloat($value);
            die unless $value >= 0 && $value <= 1;
            $mapcss{'opacity'} = $value;
        }
        else {
            die "unrecognized property for ".ref($self).": '$key'";
        }
    }
    return \%mapcss;
}

1;
