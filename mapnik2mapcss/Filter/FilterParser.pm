package FilterParser;

use strict;
use warnings;

use Parse::RecDescent;

use Rule ();
use Filter::Conjunction ();
use Filter::Disjunction ();
use Filter::FilterCondition ();

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings.
$::RD_HINT   = 1; # Give out hints to help fix problems.
#$::RD_TRACE  = 1; # Debug output (excessive)

my $grammar = <<'_EOGRAMMAR_';

    STRING : /[a-zA-Z0-9_:-]+/
    NUMBER : /[0-9]+/
    EOF: /^\Z/
 
    parse : expression EOF
    { $return = $item[1]; }
    
    expression : 
            'not' expression
        |   
            factor ...'or' ('or' factor)(s)
            {
                my @res = ();
                push(@res, $item[1]);
                for my $fac ( @{ $item[3] } ) {
                    push(@res, $fac);
                }
                $return = new Disjunction(\@res);
            }
        |
            factor ...'and' ('and' factor)(s)
            {
                my @res = ();
                push(@res, $item[1]);
                for my $fac ( @{ $item[3] } ) {
                    push(@res, $fac);
                }
                $return = new Conjunction(\@res);
            }
        |
            factor
    
    factor : 
            "(" expression ")"      
            { 
                $return = $item{expression}; 
            }    
        |
            "not" "(" expression ")" 
            {
                $return = $item{expression};
                $return->set_negated(1);
            } 
        | 
            condition 
        |
            "not" condition
            {
                $return = $item{condition};
                $return->set_negated(1);
            }
    
    condition : key op value
    { 
        print "key/$item{key}=value/$item{value}\n" if $main::debug{parseselector};
        $return = new FilterCondition($item{key}, $item{value}, $item{op});
    }
    
    key : '[' STRING ']'        { $return = $item{STRING}; }
    
    value : 
            "'" STRING "'"      { $return = $item{STRING}; }
        |
            "''"                { $return = ''; }
        |
            NUMBER              { $return = $item{NUMBER}; }
    
    op : '=' | '!=' | '<>' | '>=' | '<=' | '>' | '<'

_EOGRAMMAR_

sub new {
    return Parse::RecDescent->new($grammar);
}

1;
