package Junction;

use strict;
use warnings;

# The logical connection of a list of statements. Either Conjunction ("and") or Disjunction ("or").
# The statements can be nested expressions or simple Filter conditions.

sub new {
    my $class = shift;
    my $operands = shift;
    my $self = {
        _operands => $operands,
    };
    bless $self, $class;
    return $self;
}

sub operands {
    my $self = shift;
    return $self->{_operands};
}

sub set_operands {
    my ($self, $operands) = @_;
    $self->{_operands} = $operands;
}

sub negated {
    my $self = shift;
    return $self->{_not};
}

sub set_negated {
    my ($self, $negated) = @_;
    $self->{_not} = $negated;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($self) eq ref($other);
    return 0 unless (!!$self->negated) eq (!!$other->negated);
    my $len_self = @{$self->operands};
    my $len_other = @{$other->operands};
    return 0 unless $len_self == $len_other;
    for (my $i=0; $i<$len_self; ++$i) {
        return 0 unless $self->operands->[$i]->equals($other->operands->[$i]);
    }
    return 1;
}

sub toString {
    my $self = shift;
    my @operands = @{ $self->operands };
    if (@operands == 0) {
        return ($self->negated ? '!' : '') . '(' . substr(ref($self),0,1) . ')';
    } 
    elsif (@operands == 1) {
        return ($self->negated ? '!' : '') . '(' . substr(ref($self),0,1) . ':' . $operands[0]->toString() . ')';
    }
    else {
        return ($self->negated ? '!' : '') . '(' . join(' '.$self->connector_symbol.' ', (map { $_->toString() } @{ $self->operands })) . ')';
    }
}

1;
