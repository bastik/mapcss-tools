package Rule;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _symbolizers => []
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

sub toMapCSS {
    my ($self, $basic_type) = @_;

    my @lines = ();
    my $text;
    my $point;
    my $area;
    
    my %counter = ();
    for (@{ $self->{_symbolizers} }) {
        if ($counter{ref($_)}) {
            die "Only one symbolizer of each type (except LineSymbolizer) supported, found more than one of type '".ref($_)."'";
        }
        if ($_->isa('LineSymbolizer') || $_->isa('LinePatternSymbolizer')) {
            push(@lines, $_);
        } else {
            if ($_->isa('TextSymbolizer')) {
                $text = $_;
            } elsif ($_->isa('PointSymbolizer')) {
                $point = $_;
            } elsif ($_->isa('PolygonSymbolizer') || $_->isa('PolygonPatternSymbolizer')) {
                $area = $_;
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

    my $result = '/* \'' . $self->filename . '\', line ' . $self->linenumber . " */\n";

    if ($point) 
    {
        my $basic_selector;
        if ($basic_type eq 'point') {
            $basic_selector = 'node';
        } elsif ($basic_type eq 'polygon') {
            $basic_selector = 'area';
        } else {
            die 'Expected PointSymbolizer only for point & polygon table';
        }
        if ($basic_type eq 'point' && $area) {
            die "PolygonSymolizer, but point db table";
        }
        if (@lines) {
            die "Not supported: PointSymbolizer in combination with LineSymbolizer";
        }

        my @or_complete = map { $basic_selector . $zoom . $_ } @or;
        $result .= join(",\n", @or_complete) . " {\n";
        $result .= $point->toMapCSS();
        if ($text) {
            $result .= $text->toMapCSS();
        }
        $result .= "}\n";
    }
    elsif ($area) {
        die "Only one LineSymbolizer supported for Rules with PolygonSymbolizer" if @lines > 1;
        die unless $basic_type eq 'polygon';
        my @or_complete = map { 'area' . $zoom . $_ } @or;
        $result .= join(",\n", @or_complete) . " {\n";
        $result .= $area->toMapCSS();
        if (@lines) {
            $result .= $lines[0]->toMapCSS();
        }
        if ($text) {
            $result .= $text->toMapCSS();
        }
        $result .= "}\n";
    }
    elsif (@lines) {
        for (my $i = 0; $i < @lines; ++$i) {
            my $basic_selector = $basic_type eq 'polygon' ? 'area' : 'way';
            my @or_complete = map { $basic_selector . $zoom . $_ } @or;
            my $layer = $i == 0 ? '' : "::over$i";
            $result .= join("$layer,\n", @or_complete) . $layer . " {\n";
            $result .= $lines[$i]->toMapCSS();
            if ($text && $i == @lines - 1) {
                $result .= $text->toMapCSS();
            }
            $result .= "}\n";
        }
    }
    elsif ($text) 
    {
        my $basic_selector;
        if ($basic_type eq 'polygon') {
            $basic_selector = 'area';
        } elsif ($basic_type eq 'line') {
            $basic_selector = 'way';
        } elsif ($basic_type eq 'point') {
            $basic_selector = 'node';
        } else {
            die;
        }
        my @or_complete = map { $basic_selector . $zoom . $_ } @or;
        $result .= join(",\n", @or_complete) . " {\n";
        $result .= $text->toMapCSS();
        $result .= "}\n";
    }
    else
    {
        die 'No symbolizer at line ' . $self->linenumber;
    }
    return $result;
}

1;
