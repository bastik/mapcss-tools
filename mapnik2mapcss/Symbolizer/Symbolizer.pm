package Symbolizer;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _properties => {}
    };
    bless $self, $class;
    return $self;
}

sub set_property {
    my ($self, $key, $value) = @_;
    $self->{_properties}->{$key} = $value;
}

sub toMapCSS {
    my ($self) = @_;
    my $result = '';
    for (sort keys %{ $self->{_properties} }) {
        $result .= "    $_: $self->{_properties}->{$_};\n";
    }
    return $result;
}

1;
