package Conjunction;

use strict;
use warnings;

use Filter::Junction;

use base 'Junction';

# "and"
#
# The logical connection of a list of statements by "and".
# The statements can be nested expressions or simple Filter conditions.

sub connector_symbol {
    return '&&';
}

1;
