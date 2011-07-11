package FilterCondition;

use strict;
use warnings;

sub new {
    my ($class, $key, $value, $op) = @_;
    my $self = {
        _key => $key,
        _value => $value,
        _op => $op,
    };
    bless $self, $class;
    return $self;
}

sub key {
    my $self = shift;
    return $self->{_key};
}

sub set_key {
    my ($self, $key) = @_;
    $self->{_key} = $key;
}

sub value {
    my $self = shift;
    return $self->{_value};
}

sub set_value {
    my ($self, $value) = @_;
    $self->{_value} = $value;
}

sub operator {
    my $self = shift;
    return $self->{_op};
}

sub set_operator {
    my ($self, $operator) = @_;
    $self->{_op} = $operator;
}

sub negated {
    my $self = shift;
    return $self->{_not};
}

sub set_negated {
    my ($self, $negated) = @_;
    $self->{_not} = $negated;
}

sub toString {
    my $self = shift;
    return $self->toMapCSS();
#    return sprintf('<FilterCondition key:\'%s\', value:\'%s\', op:\'%s\'' . ($self->negated ? ', negated' : '') . '>', $self->key, $self->value, $self->operator);
}

sub toMapCSS {
    my $self = shift;
    my $op;
    if ($self->operator eq '=') {
        $op = $self->negated ? '!=' : '=';
    } elsif ($self->operator eq '!=' || $self->operator eq '<>') {
        $op = $self->negated ? '=' : '!=';
    } else {
        $op = $self->operator; # comparison operator >= <= > <
        die if $self->negated;
    }

    if ($self->value) {
        return '[' . $self->key . $op . $self->value . ']';
    } else {
        return '[' . ($op eq '=' ? '!' : '') . $self->key . ']';
    }
}

1;
