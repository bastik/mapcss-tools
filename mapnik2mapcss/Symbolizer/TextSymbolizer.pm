package TextSymbolizer;

use strict;
use warnings;

use Symbolizer::Symbolizer;
use Validate ();

use base 'Symbolizer';

sub mapcss_properties {

    my ($self, @args) = @_;
    my %hints = %{ $args[0] };
    
    my %prop = %{ $self->properties };
    my %mapcss = ();
    
    while (my ($key, $value) = each %prop) {
        if ($key eq 'fontset_name')
        {
            die unless $::fontsets{$value};
            $mapcss{'font-family'} = "\"$main::fontsets{$value}\"";
        }
        elsif ($key eq 'name')
        {
            $mapcss{'text'} = $value;
        }
        elsif ($key eq 'size')
        {
            die unless $value =~ /^\d+$/;
            $mapcss{'font-size'} = $value;
        }
        elsif ($key eq 'fill')
        {
            $mapcss{'text-color'} = Validate::color($value);
        }
        elsif ($key eq 'halo_radius')
        {
            die unless $value =~ /^\d+$/;
            $mapcss{'text-halo-radius'} = $value;
        }
        elsif ($key eq 'placement')
        {
            if ($value eq 'line') {
                $mapcss{'text-position'} = 'line';
            } else {
                die;
            }
        }
        elsif ($key eq 'dy')
        {
#            my $off = 0 - Validate::float($value);

            die 'expected icon height hint' unless (exists $hints{'icon-height'});
            my $icon_height = $hints{'icon-height'};
            
            my $off = - Validate::float($value);
            
            if ($prop{'vertical_alignment'} eq 'top')
            {
                $off -= int($icon_height / 2) + 2;
            }
            elsif ($prop{'vertical_alignment'} eq 'bottom')
            {
                $off += int($icon_height / 2);
            }
            else {
                die "unexpected 'vertical_alignment':".$prop{'vertical_alignment'}." in combination with 'dy'";
            }
            $mapcss{'text-offset-y'} = $off;
        }
        elsif ($key eq 'vertical_alignment')
        {
            #TODO: this probably needs to be adjusted a little 
            if ($value eq 'top')
            {
                $mapcss{'text-anchor-vertical'} = 'above';
            }
            elsif ($value eq 'middle')
            {
                $mapcss{'text-anchor-vertical'} = 'center';
            }
            elsif ($value eq 'bottom')
            {
                $mapcss{'text-anchor-vertical'} = 'below';
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
        elsif ($key eq 'spacing')
        {
            # Not in MapCSS yet, but sounds useful.
            $mapcss{'text-spacing'} = Validate::positiveFloat($value);
        }
        elsif ($key eq 'wrap_width')
        {
            # Not in MapCSS, but sounds reasonable.
            $mapcss{'text-wrap-width'} = Validate::positiveFloat($value);
        }
        elsif ($key eq 'min_distance')
        {
            # ignore for now
        }
        else {
            die "unrecognized property for ".ref($self).": '$key'";
        }
        
    }
    return \%mapcss;
}

1;
