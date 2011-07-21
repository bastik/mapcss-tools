package TextSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub addProperty {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'fontset_name')
    {
        die unless $::fontsets{$value};
        $self->set_property('font-family', "\"$main::fontsets{$value}\"");
    }
    elsif ($name eq 'name')
    {
        $self->set_property('text', $value);
    }
    elsif ($name eq 'size')
    {
        die unless $value =~ /^\d+$/;
        $self->set_property('font-size', $value);
    }
    elsif ($name eq 'fill')
    {
        $self->set_property('text-color', Validate::color($value));
    }
    elsif ($name eq 'halo_radius')
    {
        die unless $value =~ /^\d+$/;
        $self->set_property('text-halo-radius', $value);
    }
    elsif ($name eq 'placement')
    {
        if ($value eq 'line') {
            $self->set_property('text-position', 'line');
        } else {
            die;
        }
    }
    elsif ($name eq 'dy')
    {
        $self->set_property('text-offset-y', 0 - Validate::float($value));
    }
    elsif ($name eq 'vertical_alignment')
    {
        #TODO: this probably needs to be adjusted a little 
        if ($value eq 'top')
        {
            $self->set_property('text-anchor-vertical', 'above');
        }
        elsif ($value eq 'middle')
        {
            $self->set_property('text-anchor-vertical', 'center');
        }
        elsif ($value eq 'bottom')
        {
            $self->set_property('text-anchor-vertical', 'below');
        }
        elsif ($value eq 'auto')
        {
            die "todo";
        } 
        else 
        {
            die "unexpected value '$value' for property 'vertical_alignment'";
        }
    }
    elsif ($name eq 'spacing')
    {
        # Not in MapCSS yet, but sounds useful.
        $self->set_property('text-spacing', Validate::positiveFloat($value));
    }
    elsif ($name eq 'wrap_width')
    {
        # Not in MapCSS, but sounds reasonable.
        $self->set_property('text-wrap-width', Validate::positiveFloat($value));
    }
    elsif ($name eq 'min_distance')
    {
        # ignore for now
    }
    else {
        die "unrecognized property for ".ref($self).": '$name'";
    }
}

1;
