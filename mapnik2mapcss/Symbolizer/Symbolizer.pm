package Symbolizer;

use strict;
use warnings;

use Carp;

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

sub properties {
    my ($self) = @_;
    return $self->{_properties};
}

sub mapcss_properties {
    my ($self) = @_;
    confess 'abstract in '.ref($self);
}

sub toMapCSS {
    my ($self, @args) = @_;
    my $result = '';
    my %mapcss = %{ $self->mapcss_properties(@args) };
    for (sort keys %mapcss) {
        $result .= "    $_: $mapcss{$_};\n";
    }
    return $result;
}

1;
