package Layer;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $name = shift;
    my $self = {
        _name => $name,
    };
    bless $self, $class;
    return $self;
}

sub set_stylename {
    my ($self, $stylename) = @_;
    $self->{_stylename} = $stylename;
}

sub stylename {
    my $self = shift;
    return $self->{_stylename};
}

sub name {
    my $self = shift;
    return $self->{_name};
}

1;
