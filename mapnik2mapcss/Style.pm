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
    my ($self, $out, $basic_type, $subpart, $obect_z_index) = @_;
    my $result = '';
    for my $rule (@{ $self->{_rules} }) {
        if ($out) {
            print $out "\n";
        } else {
            $result .=  "\n";
        }
        my $rule_str =  $rule->toMapCSS($out, $basic_type, $subpart, $obect_z_index);
        $result .=  $rule_str unless (defined $out);
    }
    return $result;
}

1;
