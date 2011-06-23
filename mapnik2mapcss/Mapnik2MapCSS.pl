#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case bundling);

use XmlParser ();

### Command line options ###
#
#
# Define these hashes in the file provided by 'scale2zoom' option.
# It should map MinScaleDenominator and MaxScaleDenominator values
# to (logarithmic) slippy map zoom levels.
our (%minscale2zoom, %maxscale2zoom);
# Possible debug flags:
#   parsefilter     - debug the filter parsing
#   parsexml        - debug basic xml parsing
#   filter          - debug the filer post processing
#   result          - dump the final structure
our %debug = ();
# more verbose output - does nothing at the moment
our $verbose = 0;
# when this option is enabled, color values of the form #e1a are expanded to #ee11aa
our $expand_short_color = 0;
# try to replace hex-number by named color, if possible
our $restore_named_colors = 0;
# ignore Layer-s and simply output the Style-s
our $output_styles_only = 0;
{
    my $debug_flags_tmp = '';
    my $scale2zoom_file;
    GetOptions(
        'scale2zoom=s' => \$scale2zoom_file,
        'debug|d=s' => \$debug_flags_tmp, 
        'verbose|v' => \$verbose, 
        'expand-short-color' => \$expand_short_color,
        'restore-named-colors' => \$restore_named_colors,
        'output-styles' => \$output_styles_only,
    );
    die "Missing mandatory option --scale2zoom <FILE> for conversion of scale to zoom values.\n" unless $scale2zoom_file;
    die "Cannot find file '$scale2zoom_file'\n" unless -f $scale2zoom_file;
    require $scale2zoom_file;
    for (split(',', $debug_flags_tmp)) {
        $debug{$_} = 1;
    }
}

### font sets - hartcoded list ###

#  we could parse these automatically, but it's not worth the trouble
our %fontsets = ( 
        'book-fonts' => 'DejaVu Sans Book', 
        'bold-fonts' => 'DejaVu Sans Bold', 
        'oblique-fonts' => 'DejaVu Sans Oblique' 
);

### read file name & start parser ###
my $xmlfile = shift;
die "Cannot find file \"$xmlfile\"" unless -f $xmlfile;

my ($styles, $layers, $fontsets) = XmlParser::parse($xmlfile, 1);

### output the results ###

print "Result = ".Dumper(\$styles) if $debug{result};

if ($output_styles_only) {
    for (@$styles) {
        print "/**\n";
        print " * Style '" . $_->name . "'\n";
        print " */\n";
        print $_->toMapCSS() . "\n";
    }
} else {
    my %hstyles = ();
    for (@$styles) { $hstyles{$_->name} = $_; }
    for my $layer (@$layers) {
        print "/**\n";
        print " * Layer '" . $layer->name . "'\n";
        print " */\n";
        print $hstyles{$layer->stylename}->toMapCSS();
    }
}

