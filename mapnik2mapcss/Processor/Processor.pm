package Processor;

use strict;
use warnings;

sub new {
    my ($class, $layername, $proc) = @_;
    my $self = {
        _layername => $layername,
        _proc => $proc,
    };
    bless $self, $class;
    return $self;
}

sub proc {
    my $self = shift;
    return $self->{_proc};
}

sub execute {
    die 'abstract';
}

1;
