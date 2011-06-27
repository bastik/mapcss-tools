package XmlParserFirstPass;

use strict;
use warnings;

use Data::Dumper;
use XML::Parser;

use Layer ();

# The hash of FontSet mappings.
my %fontsets;
# Content of current xml elements
my ($fontset, $font);

# Collect the character data as it comes in chunks.
my $charData;

# Some elements can be ignored - count the level of nesting.
my $uninteresting_element;

# The list of all (Mapnik-)Layers. DB queries are too complicated to parse and
# process, so this magic has to be filled in manually.
my @layers;
# Current layer
my $layer;

# arguments for parsing
# the file to process
my $file;
# selection of layers
my %layers_selection;
my $take_all_layers = 0;

sub parse($$) {
    my $arg_layers;
    ($file, $arg_layers) = @_;

    if ($arg_layers) {
        %layers_selection = ();
        for (@{ $arg_layers }) { $layers_selection{$_} = 0; }
    } else {
        $take_all_layers = 1;
    }

    @layers = ();
    %fontsets = ();
    undef $layer;
    undef $fontset;

    $charData = '';

    $uninteresting_element = 0;

    my $parser = new XML::Parser;
    $parser->setHandlers(
        Start => \&startElement,
        End => \&endElement,
        Char => \&characterData
    );
    $parser->parsefile($file);

    return (\%fontsets, \@layers);
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
        # ignore
    }
    elsif ($element eq 'FontSet')
    {
        $fontset = $attributes{'name'};
        die unless $fontset;
        undef $font;
    }
    elsif ($element eq 'Font')
    {
        die unless $fontset;
        die 'only one Font within FontSet expected at line ' . $parser_instance->current_line if $font;
        $font = $attributes{'face_name'};
        die unless $font;
    }
    elsif ($element eq 'Layer')
    {
        my $name = $attributes{'name'};
        die unless $name;
        if ($take_all_layers or exists $layers_selection{$name}) 
        {
            $layer = Layer->new($name);
        }
    }
    elsif ($element eq 'StyleName')
    {
        # handle when element is closed
    }
    elsif ($element eq 'Datasource')
    {
        # not supported
        ++$uninteresting_element;
    }
    elsif ($element eq 'Style')
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
    elsif ($element eq 'Layer')
    {
        if ($layer) 
        {
            push @layers, $layer;
            undef $layer;
        }
    }
    elsif ($element eq 'FontSet') 
    {
        die unless $fontset;
        die unless $font;
        $fontsets{$fontset} = $font;
        undef $fontset;
        undef $font;
    }
    elsif ($element eq 'StyleName')
    {
        if ($layer) {
            die unless $charData;
            $layer->set_stylename($charData);
        }
    }
}

sub characterData {
    my($parseinst, $data) = @_;
    $charData .= $data;
}

1;
