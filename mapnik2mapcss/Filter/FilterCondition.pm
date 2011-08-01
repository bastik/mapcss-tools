package FilterCondition;

use strict;
use warnings;

sub new {
    my ($class, $key, $value) = @_;
    my $op = @_ > 3 ? $_[3] : '=';
    my $self = {
        _key => $key,
        _value => $value,
        _op => $op,
    };
    bless $self, $class;
    if ($op eq '<>' || $op eq '!=') {
        $self->set_operator('=');
        $self->set_negated(1);
    }
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

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($self) eq ref($other);
    return equal($self->key, $other->key)
        && equal($self->value, $other->value)
        && equal($self->operator, $other->operator)
        && !!$self->negated eq !!$other->negated;
}

sub equal {
    my ($a, $b) = @_;
    return 1 if !defined $a && !defined $b;
    return 1 if defined $a && defined $b && $a eq $b;
    return 0;
}

sub toMapCSS {
    my $self = shift;
    my $op;
    if ($self->operator eq '=') {
        $op = $self->negated ? '!=' : '=';
    } elsif ($self->operator eq '!=' || $self->operator eq '<>') {
        die 'assertion error';
    } else {
        $op = $self->operator; # comparison operator >= <= > <
        die 'not supported' if $self->negated;
    }

    if (defined $self->value && !($self->value eq '')) {
        if ($self->value eq '#magic_yes') {
            die 'assertion error' unless $self->operator eq '=';
            if ($self->negated) {
                if ($main::yes_true_1_magic_style eq 'halcyon') {
                    return '[' . $self->key . '!=yes]';
                } else {
                    return '[!' . $self->key . '?]';
                }
            } else {
                if ($main::yes_true_1_magic_style eq 'halcyon') {
                    return '[' . $self->key . '=yes]';
                } else {
                    return '[' . $self->key . '?]';
                }
            }
        } else {
            return '[' . $self->key . $op . $self->value . ']';
        }
    } else {
        return '[' . ($self->negated ? '' : '!') . $self->key . ']';
    }
}

1;
