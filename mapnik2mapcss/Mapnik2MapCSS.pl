#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;

use Filter::FilterNormalizer ();
use XmlParserFirstPass ();
use XmlParserSecondPass ();

### Command line options ###
#
# Define these hashes in the file provided by 'scale2zoom' option.
# It should map MinScaleDenominator and MaxScaleDenominator values
# to (logarithmic) slippy map zoom levels.
our (%minscale2zoom, %maxscale2zoom);
# The names of the layers that should be parsed. (All layers are included if argument is missing.)
our @layer_selection;
# Change Filters that contain internal keywords.
our %special_processors;
# Possible debug flags:
#   parsefilter     - debug the filter parsing
#   parsexml        - debug basic xml parsing
#   filter          - debug the filer post processing
#   result          - dump the final structure
our %debug = ();
# more verbose output
our $args_verbose = 0;
# when this option is enabled, color values of the form #e1a are expanded to #ee11aa
our $args_expand_short_color = 0;
# try to replace hex-number by named color, if possible
our $args_restore_named_colors = 0;
# ignore Layer-s and simply output the Style-s
our $args_output_styles_only = 0;
{
    my $debug_flags_tmp = '';
    my $scale2zoom_file;
    my $layers_tmp;
    my $special_processors_file;
    my $help;
    GetOptions(
        'scale2zoom=s' => \$scale2zoom_file,
        'layers=s' => \$layers_tmp,
        'special-processors=s' => \$special_processors_file,
        'debug|d=s' => \$debug_flags_tmp,
        'verbose|v' => \$args_verbose,
        'expand-short-color' => \$args_expand_short_color,
        'restore-named-colors' => \$args_restore_named_colors,
        'output-styles' => \$args_output_styles_only,
        'help|h' => \$help,
    ) or pod2usage(-verbose => 0);
    pod2usage(-verbose => 2, -noperldoc => 1) if $help;
    pod2usage(
        -message => "Missing mandatory option --scale2zoom SCALE2ZOOM_FILE for conversion of scale to zoom values.\n"
                    ."Try '$0 --help' for more information.\n",
        -verbose => 0
    ) unless $scale2zoom_file;

    die "$0: Cannot find file '$scale2zoom_file'\n" unless -f $scale2zoom_file;
    require $scale2zoom_file;
    for (split(',', $debug_flags_tmp)) {
        $debug{$_} = 1;
    }
    @layer_selection = ();
    if ($layers_tmp) {
        @layer_selection = split(',', $layers_tmp);
    }
    if ($special_processors_file) {
        die "$0: Cannot find file '$special_processors_file'\n" unless -f $special_processors_file;
        require $special_processors_file;
    }
}

### read file name ###
my $xmlfile = shift;
die "Cannot find file \"$xmlfile\"" unless -f $xmlfile;

print "== Parser: 1st pass ==\n" if $args_verbose;
our %fontsets;
our @layers;
{
    my ($fontsets, $layers) = XmlParserFirstPass::parse($xmlfile, \@layer_selection);
    %fontsets = %{ $fontsets };
    @layers = @{ $layers };
}

print "== Parser: 2nd pass ==\n" if $args_verbose;
our @styles;
{
    my %style_selection = ();
    for (@layers) {
        $style_selection{ $_->stylename } = 1;
        print 'found layer \''.$_->name.'\' using style \''.$_->stylename."'\n" if $args_verbose;
    }
    my $styles = XmlParserSecondPass::parse($xmlfile, \%style_selection);
    @styles = @{ $styles };
}

print "== Find corresponding Style for selected Layers ==\n" if $args_verbose;
{
    my %hstyles = ();
    for (@styles) { $hstyles{$_->name} = $_; }
    for my $layer (@layers) {
        die 'Could not find style \''.$layer->stylename.'\' for layer '.$layer->name
            unless exists $hstyles{$layer->stylename};
        $layer->set_style($hstyles{$layer->stylename});
    }
}

print "== Apply special layer rules ==\n" if $args_verbose;
for my $layer (@layers) {
    my $processor = $special_processors{$layer->name};
    if ($processor) {
        print 'appying special processor for layer '.$layer->name."\n" if $args_verbose;
        for my $rule (@{ $layer->style->rules }) {
            my $filter = $rule->filter;
            my $process_rec;
            $process_rec = sub {
                my $e = shift;
                if ($e->isa('FilterCondition')) 
                {
                    return $processor->($e);
                } 
                elsif ($e->isa('Junction')) 
                {
                    my @operands = @{ $e->operands };
                    for (my $i=0; $i < @operands; ++$i) {
                        $operands[$i] = $process_rec->($operands[$i]);
                    }
                    $e->set_operands(\@operands);
                    return $e;
                }
                else
                {
                    die;
                }
            };
            $rule->set_filter($process_rec->($filter));
        }
    }
}

#print "== Normalizing Filters ==\n" if $args_verbose;

for my $layer (@layers) {
    for my $rule (@{ $layer->style->rules }) {
        my $filter = $rule->filter;
        $filter = FilterNormalizer::normalize_filter($filter);
        print "Normalized Parsed Filter:\n    ". $filter->toString() . "\n" if $main::debug{filter};
        $rule->set_filter($filter);
    }
}

### output the results ###

print "Result = ".Dumper(\@styles) if $debug{result};

if ($args_output_styles_only) {
    for (@styles) {
        print "/**\n";
        print " * Style '" . $_->name . "'\n";
        print " */\n";
        print $_->toMapCSS() . "\n";
    }
} else {
    for my $layer (@layers) {
        print "\n";
        print "/**\n";
        print " * Layer '" . $layer->name . "'\n";
        print " */\n";
        print $layer->style->toMapCSS();
    }
}
__END__

=head1 NAME

Mapnik2MapCSS - Script to convert Mapnik xml to MapCSS

=head1 SYNOPSIS

    ./Mapnik2MapCSS.pl --scale2zoom SCALE2ZOOM_FILE [options] -- INPUT_FILE

=head1 OPTIONS

=over 12

=item B<--scale2zoom FILE>

Provide a file that contains a hash to convert scale values from C<< <MaxScaleDenominator> >> and C<< <MinScaleDenominator> >> elements into MapCSS Zoom values (mandatory argument). Actually the OSM Mapnik template contain C<&maxscale_zoomX;> entities, this is just, what is needed. For an example of a valid scale2zoom file, see C<examples/scale2zoom.pl>.

=item B<--layers>

Specify the layers to parse, i.e. for

 <Layer name="layer1" ...> ... </Layer>
 <Layer name="layer2" ...> ... </Layer>
 ...

write

    --layers layer1,layer2

When this option is omitted, all layers from the input file are used. Each layer refers to a certain Style element. A Style is not parsed, unless it is referenced by one of the selected layers.

=item B<--special-processors FILE>

The Layer element may contain Database queries, that introduce special keywords, like C<[religion]='INT-generic'>. With this option you can hook into Filter processing and change certain elements. An example is given in C<examples/special_processors.pl>.

=item B<--help / -h>

Show this help.

=item B<--restore-named-colors>

Replaces numeric colors by their CSS color names, if the given color has a name. E.g. C<< #000000 -> black >>.

=back

