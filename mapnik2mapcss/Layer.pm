package Layer;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $name = shift;
    my $self = {
        _name => $name,
        # For the first parser pass, this array collects the names of the referenced styles.
        # The joined list of style names required by all layers is passed to the 2nd pass parser.
        # After 2nd pass, the style names are replaced by real Style objects.
        _styles => [],
    };
    bless $self, $class;
    return $self;
}

sub styles {
    my $self = shift;
    return $self->{_styles};
}

sub add_style {
    my ($self, $style) = @_;
    push @{ $self->{_styles} }, $style;
}

sub set_styles {
    my ($self, $styles) = @_;
    $self->{_styles} = $styles;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

1;
