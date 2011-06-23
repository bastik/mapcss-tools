package Disjunction;

use strict;
use warnings;

use Filter::Junction;

use base 'Junction';

# "or"

sub connector_symbol {
    return '||';
}

1;
