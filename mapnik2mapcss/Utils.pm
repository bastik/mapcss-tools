package Utils;

use strict;
use warnings;

sub toString($) {
    my $o = shift;
    if (ref($o) eq 'ARRAY') {
        return '[' . join(', ', (map { toString($_) } @$o)) . ']';
    } elsif (ref($o) eq 'HASH') {
        return Dumper($o); #FIXME
    } elsif (ref($o) && UNIVERSAL::can($o, 'toString')) {
        return $o->toString();
    } else {
        return $o;
    }
}

1;
