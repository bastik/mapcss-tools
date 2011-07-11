package Style;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _rules => [],
    };
    bless $self, $class;
    return $self;
}

sub addRule {
    my ($self, $rule) = @_;
    die unless $rule->isa('Rule');
    push @{ $self->{_rules} }, $rule;
}

sub rules {
    my $self = shift;
    return $self->{_rules};
}

sub set_name {
    my ($self, $name) = @_;
    $self->{_name} = $name;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

# Sets the line number of the mapnix xml file, where this Style begins.
sub set_linenumber {
    my ($self, $linenumber) = @_;
    $self->{_linenumber} = $linenumber;
}

sub toMapCSS {
    my $self = shift;
    my $result = '';
    for (@{ $self->{_rules} }) {
        $result .=  "\n" . $_->toMapCSS();
    }
    return $result;
}

1;
