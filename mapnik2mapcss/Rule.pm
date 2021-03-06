package Rule;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _symbolizers => [],
        _hints => {},
    };
    bless $self, $class;
    return $self;
}

sub filter {
    my $self = shift;
    return $self->{_filter};
}

sub set_filter {
    my ($self, $filter) = @_;
    $self->{_filter} = $filter;
}

sub maxzoom {
    my $self = shift;
    return $self->{_maxzoom};
}

sub set_maxzoom {
    my ($self, $val) = @_;
    $self->{_maxzoom} = $val;
}

sub minzoom {
    my $self = shift;
    return $self->{_minzoom};
}

sub set_minzoom {
    my ($self, $val) = @_;
    $self->{_minzoom} = $val;
}

sub linenumber {
    my $self = shift;
    return $self->{_linenumber};
}

# Sets the line number of the mapnix xml file, where this Rule begins.
sub set_linenumber {
    my ($self, $linenumber) = @_;
    $self->{_linenumber} = $linenumber;
}

sub filename {
    my $self = shift;
    return $self->{_filename};
}

# Sets the file name of the source mapnix xml file for this rule.
sub set_filename {
    my ($self, $filename) = @_;
    $self->{_filename} = $filename;
}

sub addSymbolizer {
    my ($self, $symb) = @_;
    die unless $symb->isa('Symbolizer');
    push(@{ $self->{_symbolizers} }, $symb);
}

sub hint {
    my ($self, $key) = @_;
    return $self->{_hints}->{$key};
}

sub hints {
    my ($self) = @_;
    return $self->{_hints};
}

#####################
# possible hints: 
#  * closed     Adds :closed pseudo selector.
#  * under      When there are multiple LineSymbolizers, treats the last
#               one as the "main" stroke and the previous ones get negative
#               z-index. Otherwise the first line is the proper line and the
#               others are mere overlays.
#               The value of the 'under' hint determines the subpart name.
#  * flat       Do not adjust the z-index of overlays, keep them on the same
#               level as the main stroke (probably because they do not overlap).
#  * concat     A sub that concatinates the string elements of a selector.
#               (To override the default behaviour.)
#  * z-index    Overrides the layer z-index.
#  * join       When db query is a join operation, this sets the basic
#               selector.
#  * subpart    Select subpart for this rule.
#  * text-position=center
#               Sets the mapcss property text-position=center for text symbolizers.
#                
sub put_hint {
    my ($self, $key, $value) = @_;
    $self->{_hints}->{$key} = $value;
}

sub toMapCSS {
    my ($self, $out, $basic_type, $subpart, $z_index) = @_;

    if ($self->hint('skip')) {
        return '';
    }
    if (defined $self->hint('subpart')) {
        $subpart = $self->hint('subpart');
    }
    
    my @lines = ();
    my @texts = ();
    my $point;
    my $area;
    my $shield;
    
    my %counter = ();
    for (@{ $self->{_symbolizers} }) {
        if ($counter{ref($_)}) {
            die "Only one symbolizer of each type (except LineSymbolizer and TextSymbolizer) supported, found more than one of type '".ref($_)."' at l. ".$self->linenumber.' f.';
        }
        if ($_->isa('LineSymbolizer') || $_->isa('LinePatternSymbolizer')) {
            push(@lines, $_);
        } elsif ($_->isa('TextSymbolizer')) {
            push(@texts, $_);
        } else {
            if ($_->isa('PointSymbolizer')) {
                $point = $_;
            } elsif ($_->isa('PolygonSymbolizer') || $_->isa('PolygonPatternSymbolizer')) {
                $area = $_;
            } elsif ($_->isa('ShieldSymbolizer')) {
                $shield = $_;
            } else {
                die;
            }
            ++$counter{ref($_)};
        }
    }

    my $zoom = '';
    if ($self->minzoom && $self->maxzoom) {
        if ($self->minzoom eq $self->maxzoom) {
            $zoom = '|z' . $self->minzoom;
        } else {
            $zoom = '|z' . $self->maxzoom . '-' . $self->minzoom;
        }
    } elsif ($self->minzoom) {
        $zoom = '|z-' . $self->minzoom;
    } elsif ($self->maxzoom) {
        $zoom = '|z' . $self->maxzoom . '-';
    }
    
    my @or = ();
    for my $ord (@{ $self->filter->operands }) {
        my $and = '';
        for (@{ $ord->operands }) {
            $and .= $_->toMapCSS();
        }
        push(@or, $and);
    }
    die unless @or;

    my $basic_selector;
    my $closed = '';
    # multiple declarations, each one gets its own subpart
    # each is a list of symbolizers
    my @declarations = ();
    
    if ($point)
    {
        if ($basic_type eq 'point') {
            $basic_selector = 'node';
        } elsif ($basic_type eq 'polygon') {
            $basic_selector = 'area';
        } elsif ($self->hint('join')) {
            $basic_selector = $self->hint('join');
        } else {
            die 'Expected PointSymbolizer only for point & polygon table';
        }
        if ($basic_type eq 'point' && $area) {
            die "PolygonSymolizer, but point db table";
        }
        if (@lines) {
            die "Not supported: PointSymbolizer in combination with LineSymbolizer";
        }
        if (@texts > 1) {
            die "Not supported: PointSymbolizer in combination with more than one TextSymbolizer";
        }
        my @symbolizers = ($point);
        push @symbolizers, $texts[0] if @texts;
        push @declarations, \@symbolizers;
    }
    elsif ($area) {
        die "Only one LineSymbolizer supported for Rules with PolygonSymbolizer" if @lines > 1;
        die unless $basic_type eq 'polygon';
        $basic_selector = 'area';
        $closed = $self->hint('closed') ? ':closed' : '';

        if (@texts > 1) {
            die "Not supported: PolygonSymbolizer in combination with more than one TextSymbolizer";
        }
        
        my @symbolizers = ($area);
        push @symbolizers, $lines[0] if @lines;
        push @symbolizers, $texts[0] if @texts;
        @declarations = (\@symbolizers);
    }
    elsif (@lines) {
        $basic_selector = $basic_type eq 'polygon' ? 'area' : 'way';
        $closed = $self->hint('closed') ? ':closed' : '';

        if (@texts > 1) {
            die "Not supported: LineSymbolizer in combination with more than one TextSymbolizer";
        }
        
        for (my $i = 0; $i < @lines; ++$i) {
            my @symbolizers = ($lines[$i]);
            push @symbolizers, $texts[0] if @texts && $i == @lines - 1;
            push @declarations, \@symbolizers;
        }
    }
    elsif (@texts) 
    {
        if ($basic_type eq 'polygon') {
            $basic_selector = 'area';
        } elsif ($basic_type eq 'line') {
            $basic_selector = 'way';
        } elsif ($basic_type eq 'point') {
            $basic_selector = 'node';
        } elsif ($self->hint('join')) {
            $basic_selector = $self->hint('join');
        } else {
            die;
        }
        for (@texts) {
            my @symbolizers = ($_);
            push @declarations, \@symbolizers;
        }
    }
    elsif ($shield)
    {
        # ignore for now
        $basic_selector = 'way';
        my @symbolizers = ();
        push @declarations, \@symbolizers;
    }
    else
    {
        die 'No symbolizer at line ' . $self->linenumber;
    }

    my $result = '';
    my $output = sub {
        my $str = shift;
        if ($out) {
            print $out $str;
        } else {
            $result .= $str;
        }
    };
    $output->('/* \'' . $self->filename . '\', line ' . $self->linenumber . " */\n");

    for (my $i = 0; $i < @declarations; ++$i) {
        my $symbolizers = $declarations[$i];
        my $layer;
        if ($self->hint('under')) {
            if ($subpart) {
                $layer = $i == @declarations - 1 ? "::$subpart" : "::${subpart}_" . $self->hint('under') . (@declarations - $i);
            } else {
                $layer = $i == @declarations - 1 ? '' : "::" . $self->hint('under') . (@declarations - $i - 1);
            }
        } else {
            if ($subpart) {
                $layer = $i == 0 ? "::$subpart" : "::${subpart}_over$i";
            } else {
                $layer = $i == 0 ? '' : "::over$i";
            }
        }
        my $concat = $self->hint('concat') ? $self->hint('concat') :
            sub {
                my ($basic_selector, $zoom, $conditions, $closed, $layer) =  @_;
                return "${basic_selector}${zoom}${conditions}${closed}${layer}";
            };
        my @or_complete = ();
        for my $conditions (@or) {
            push @or_complete, $concat->($basic_selector, $zoom, $conditions, $closed, $layer);
        }
        $output->(join(",\n", @or_complete) . " {\n");
        for my $symbolizer (@$symbolizers) {
            $output->($symbolizer->toMapCSS($self->hints));
        }
        my $this_z_index;
        if ($self->hint('under')) {
            if ($i < @declarations) {
                $this_z_index = -(@declarations - $i - 1) / 10.0;
            }
        } else {
            if ($i > 0) {
                $this_z_index = $i / 10.0;
            }
        }
        if ($self->hint('flat')) {
            undef $this_z_index;
        }
        if ($self->hint('z-index')) {
            $z_index = $self->hint('z-index');
        }
        if (defined $z_index) {
            $this_z_index = $z_index + (defined $this_z_index ? $this_z_index : 0);
        }
        if (defined $this_z_index) {
            $output->("    z-index: $this_z_index;\n");
        }
        $output->("}\n");
    }
    return $result;
}

1;
