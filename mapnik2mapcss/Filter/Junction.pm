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
