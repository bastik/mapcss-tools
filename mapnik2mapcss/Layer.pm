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

sub datasource {
    my $self = shift;
    return $self->{_datasource};
}

sub set_datasource {
    my ($self, $datasource) = @_;
    $self->{_datasource} = $datasource;
}

sub basictype {
    my $self = shift;
    if ($self->datasource) {
        return $self->datasource->basictype;
    }
    return undef;
}

sub subparts {
    my $self = shift;
    return $self->{_subpart};
}

sub set_subpart {
    my ($self, $style_name, $subpart) = @_;
    $self->{_subpart}->{$style_name} = $subpart;
}

sub z_indices {
    my $self = shift;
    return $self->{_z_index};
}

sub set_z_index {
    my ($self, $style_name, $z_index) = @_;
    $self->{_z_index}->{$style_name} = $z_index;
}

sub toMapCSS {
    my ($self, $out) = @_;
    my $result = '';
    my $layer_comment = '';
    $layer_comment .= "\n";
    $layer_comment .= "/**\n";
    $layer_comment .= " * Layer '" . $self->name . "'\n";
    if ($out) {
        print $out $layer_comment;
    } else {
        $result .= $layer_comment;
    }
    my @styles = @{ $self->styles };
    for (my $i=0; $i<@styles; ++$i) {
        my $style = $styles[$i];
        my $style_comment = '';
        if ($i == 0) {
            $style_comment .= " * Style '".$style->name."'\n";
            $style_comment .= " */\n";
        } else {
            $style_comment .= "\n";
            $style_comment .= "/* Style '".$style->name."' */\n";
        }
        if (defined $out) {
            print $out $style_comment;
        } else {
            $result .= $style_comment;
        }
        my $style_str = $style->toMapCSS($out, $self->basictype, $self->subparts, $self->z_indices);
        $result .= $style_str unless $out;
    }
    return $result;
}

1;
