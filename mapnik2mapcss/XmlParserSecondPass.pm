package XmlParserSecondPass;

use strict;
use warnings;

use Data::Dumper;
use XML::Parser;

use Layer ();
use Style ();
use Utils ();
use Filter::FilterNormalizer ();
use Filter::FilterParser ();
use Symbolizer::LineSymbolizer ();
use Symbolizer::PolygonPatternSymbolizer ();
use Symbolizer::PolygonSymbolizer ();
use Symbolizer::PointSymbolizer ();
use Symbolizer::TextSymbolizer ();

use constant SYMBOLIZERS => {
    'LineSymbolizer' => 1,
    'TextSymbolizer' => 1,
    'PointSymbolizer' => 1,
    'PolygonPatternSymbolizer' => 1,
    'PolygonSymbolizer' => 1,
};

# The list of all (Mapnik-)Styles, partly processed for MapCSS output.
my @styles;
# The current xml element or its parent.
my ($style, $rule, $symbolizer, $css_name);

# Collect the character data as it comes in chunks.
my $charData;

# Some elements can be ignored - count the level of nesting.
my $uninteresting_element;

my $filterParser;

## options provided by 'parse'

# normalize the filter for MapCSS output?
my $normalizeFilter;
# the selection of styles to parse
my %style_selection;
# the file to process
my $file;

# set up and run the parser
sub parse($$$) {
    $file = shift;
    my $style_selection_tmp = shift;
    %style_selection = %{ $style_selection_tmp };
    $normalizeFilter = shift;

    @styles = ();
    undef $style;
    undef $rule;
    undef $symbolizer;
    undef $css_name;

    $charData = '';
    
    $uninteresting_element = 0;

    $filterParser = new FilterParser();

    my $parser = new XML::Parser;
    $parser->setHandlers(
        Start => \&startElement,
        End => \&endElement,
        Char => \&characterData,
        Default => \&default
    );
    $parser->parsefile($file);
    
    return \@styles;
}

sub startElement {
    my ($parser_instance, $element, %attributes) = @_;

    $charData = '';

    if ($uninteresting_element) # inside an uninteresting element
    {
        ++$uninteresting_element; # go one level deeper
    }
    elsif ($element eq 'Map')
    {
        # do nothing
    }
    elsif ($element eq 'Style') 
    {
        die if $style;
        my $name = $attributes{'name'};
        die unless $name;
        if (exists $style_selection{$name}) {
            $style = new Style();
            $style->set_name($name);
            $style->set_linenumber($parser_instance->current_line);
        } else {
            ++$uninteresting_element;
        }
    }
    elsif ($element eq 'Rule') 
    {
        die unless $style;
        $rule = new Rule();
        $rule->set_linenumber($parser_instance->current_line);
        $rule->set_filename($file);
    }
    elsif ($element eq 'Filter') 
    {
        die unless $rule;
    }
    elsif (SYMBOLIZERS->{$element}) 
    {
        die unless $rule;
        die if $symbolizer;
        $symbolizer = $element->new;
        for (keys %attributes) {
            $symbolizer->addProperty($_, $attributes{$_});
        }
    }
    elsif ($element eq 'CssParameter')
    {
        die unless $symbolizer;
        die if $css_name;
        $css_name = $attributes{'name'};
        die unless $css_name;
    }
    elsif ($element eq 'MinScaleDenominator' || $element eq 'MaxScaleDenominator')
    {
        # handle when element is closed
    }
    elsif ($element eq 'FontSet' or $element eq 'Layer')
    {
        ++$uninteresting_element;
    }
    else 
    {
        die "Unknown element: '$element' at line " . $parser_instance->current_line;
    }

    if ($main::debug{parsexml}) {
        print "<$element>";
        print '(uninteresting)' if ($uninteresting_element);
        print "\n";
    }
}

sub endElement {
    my ($parser_instance, $element) = @_;

    if ($uninteresting_element)
    {
        --$uninteresting_element;
    }
    elsif ($element eq 'Style')
    {
        if ($style) {
            push @styles, $style;
            undef $style;
        }
    }
    elsif ($element eq 'Rule')
    {
        $style->addRule($rule);
        undef $rule;
    }
    elsif ($element eq 'Filter')
    {
        die 'only one filter per rule supported' if $rule->filter;
        $charData = Utils::trim($charData);

        print "Filter:$charData\n" if $main::debug{filter};

        my $filter = $filterParser->parse($charData);
        defined($filter) || die "unable to parse $charData";

        print "Parsed Filter:\n    " . $filter->toString() . "\n" if $main::debug{filter};

        if ($normalizeFilter) {
            $filter = FilterNormalizer::normalize_filter($filter);

            print "Normalized Parsed Filter:\n    ". $filter->toString() . "\n" if $main::debug{filter};
        }

        $rule->set_filter($filter);
    }
    elsif (SYMBOLIZERS->{$element})
    {
        $rule->addSymbolizer($symbolizer);
        undef $symbolizer;
    }
    elsif ($element eq 'CssParameter')
    {
        $symbolizer->addProperty($css_name, $charData);
        undef $css_name;
    }
    elsif ($element eq 'MinScaleDenominator')
    {
        die unless $rule;
        die unless $main::minscale2zoom{$charData};
        $rule->set_minzoom($main::minscale2zoom{$charData});
    }
    elsif ($element eq 'MaxScaleDenominator')
    {
        die unless $rule;
        die unless $main::maxscale2zoom{$charData};
        $rule->set_maxzoom($main::maxscale2zoom{$charData});
    }
}

sub characterData {
    my($parseinst, $data) = @_;
    $charData .= $data;
    print "[$data]\n" if ($main::debug{parsexml} && ! ($data =~ /\s+/));
}

sub default {
    my($parseinst, $data) = @_;
    if ($rule) {
        if ($data =~ /&minscale_zoom(\d+);/) {
            $rule->set_minzoom($1);
        }
        if ($data =~ /&maxscale_zoom(\d+);/) {
            $rule->set_maxzoom($1);
        }
    }
    print "{$data}\n" if ($main::debug{parsexml} && ! ($data =~ /\s+/));
}

1;
