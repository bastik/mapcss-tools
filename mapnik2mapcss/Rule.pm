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

sub put_hint {
    my ($self, $key, $value) = @_;
    $self->{_hints}->{$key} = $value;
}

sub toMapCSS {
    my ($self, $out, $basic_type, $subpart, $z_index) = @_;

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

    my $basic_selector;
    my $closed = '';
    my @declarations = ();
    
    if ($point)
    {
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
        my @symbolizers = ($point);
        push @symbolizers, $text if $text;
        push @declarations, \@symbolizers;
    }
    elsif ($area) {
        die "Only one LineSymbolizer supported for Rules with PolygonSymbolizer" if @lines > 1;
        die unless $basic_type eq 'polygon';
        $basic_selector = 'area';
        $closed = $self->hint('closed') ? ':closed' : '';
        
        my @symbolizers = ($area);
        push @symbolizers, $lines[0] if @lines;
        push @symbolizers, $text if $text;
        @declarations = (\@symbolizers);
    }
    elsif (@lines) {
        $basic_selector = $basic_type eq 'polygon' ? 'area' : 'way';
        $closed = $self->hint('closed') ? ':closed' : '';
        
        for (my $i = 0; $i < @lines; ++$i) {
            my @symbolizers = ($lines[$i]);
            push @symbolizers, $text if $text && $i == @lines - 1;
            push @declarations, \@symbolizers;
        }
    }
    elsif ($text) 
    {
        if ($basic_type eq 'polygon') {
            $basic_selector = 'area';
        } elsif ($basic_type eq 'line') {
            $basic_selector = 'way';
        } elsif ($basic_type eq 'point') {
            $basic_selector = 'node';
        } else {
            die;
        }
        @declarations = ([$text]);
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
        if ($subpart) {
            $layer = $i == 0 ? "::$subpart" : "::${subpart}_over$i";
        } else {
            $layer = $i == 0 ? '' : "::over$i";
        }
        my @or_complete = map { $basic_selector . $zoom . $_ . $closed . $layer } @or;
        $output->(join(",\n", @or_complete) . " {\n");
        for my $symbolizer (@$symbolizers) {
            $output->($symbolizer->toMapCSS());
        }
        if (defined $z_index) {
            $output->("    z-index: $z_index;\n");
        }
        $output->("}\n");
    }
    return $result;
}

1;
