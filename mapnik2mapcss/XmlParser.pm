package XmlParser;

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

# The list of all (Mapnik-)Layers. DB queries are too complicated to parse and
# process, so this magic has to be filled in manually.
my @layers;
my $layer;

# The hash of FontSet mappings.
my %fontsets;
my ($fontset, $font);

# Collect the character data as it comes in chunks.
my $charData;

my $filterParser;

## options provided by 'parse'

# normalize the filter for MapCSS output?
my $normalizeFilter;
# the file to process
my $file;

# set up and run the parser
sub parse($$) {
    $file = shift;
    $normalizeFilter = shift;   

    @styles = ();
    @layers = ();
    %fontsets = ();
    undef $style;
    undef $rule;
    undef $symbolizer;
    undef $css_name;
    undef $layer;
    undef $fontset;

    $charData = '';
    
    $filterParser = new FilterParser();
    
    my $parser = new XML::Parser;

    $parser->setHandlers(
        Start => \&startElement,
        End => \&endElement,
        Char => \&characterData,
        Default => \&default);

    $parser->parsefile($file);
    return (\@styles, \@layers, \%fontsets);
}

sub startElement {
    my($parseinst, $element, %attrs) = @_;
    
    $charData = '';
    
    if ($element eq 'Map') {
    }
    elsif ($element eq 'Style') {
        die if $style;
        $style = new Style();
        die unless $attrs{'name'};
        $style->set_name($attrs{'name'});
        $style->set_linenumber($parseinst->current_line);
    }
    elsif ($element eq 'Rule') {
        die unless $style;
        $rule = new Rule();
        $rule->set_linenumber($parseinst->current_line);
        $rule->set_filename($file);
    }
    elsif ($element eq 'Filter') {
        die unless $rule;
    }
    elsif (SYMBOLIZERS->{$element}) {
        die unless $rule;
        die if $symbolizer;
        $symbolizer = $element->new;
        for (keys %attrs) {
            $symbolizer->addProperty($_, $attrs{$_});
        }
    }
    elsif ($element eq 'CssParameter')
    {
        die unless $symbolizer;
        die if $css_name;
        $css_name = $attrs{'name'};
        die unless $css_name;
    }
    elsif ($element eq 'FontSet')
    {
        die if $fontset;
        $fontset = $attrs{'name'};
        die unless $fontset;
        undef $font;
    }
    elsif ($element eq 'Font')
    {
        die unless $fontset;
        die 'only one Font within FontSet expected at line ' . $parseinst->current_line if $font;
        $font = $attrs{'face_name'};
        die unless $font;
        
    }
    elsif ($element eq 'Layer')
    {
        die unless $attrs{'name'};
        $layer = Layer->new($attrs{'name'});
    }
    elsif ($element eq 'MinScaleDenominator' || $element eq 'MaxScaleDenominator')
    {
        # handle when element is closed
    }
    elsif ($layer) 
    {
        # ignore stuff inside layer element
    }
    else {
        die "Unknown element: '$element' at line " . $parseinst->current_line;
    }

    print "$element\n" if $main::debug{parsexml};
}

sub endElement {
    my ($parseinst, $element) = @_;
    if ($element eq 'Style') 
    {
        push @styles, $style;
        undef $style;
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
    elsif ($element eq 'Layer') {
        push @layers, $layer;
        undef $layer;
    }
    elsif ($element eq 'StyleName') {
        die unless $layer;
        die unless $charData;
        $layer->set_stylename($charData);
    } elsif ($element eq 'FontSet') {
        die unless $fontset;
        die unless $font;
        $fontsets{$fontset} = $font;
        undef $fontset;
        undef $font;
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
