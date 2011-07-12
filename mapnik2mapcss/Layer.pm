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

sub toMapCSS {
    my $self = shift;
    my $result = '';
    $result .= "\n";
    $result .= "/**\n";
    $result .= " * Layer '" . $self->name . "'\n";
    my @styles = @{ $self->styles };
    for (my $i=0; $i<@styles; ++$i) {
        my $style = $styles[$i];
        if ($i == 0) {
            $result .= " * Style '".$style->name."'\n";
            $result .= " */\n";
        } else {
            $result .= "\n";
            $result .= "/* Style '".$style->name."' */\n";
        }
        $result .= $style->toMapCSS($self->basictype);
    }
    return $result;
}

1;
