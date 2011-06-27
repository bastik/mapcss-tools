package Validate;

use strict;
use warnings;

use Constants;

sub color($) {
    my $value = shift;
    if ($value =~ /^#([[:xdigit:]])([[:xdigit:]])([[:xdigit:]])$/) 
    {
        if ($main::args_expand_short_color) {
            return "#$1$1$2$2$3$3";
        } else {
            return $value;
        }
    } 
    elsif (($value =~ /^#[[:xdigit:]]{6}$/) or exists Constants::CSS_COLORS->{$value}) 
    {
        return $value;
    }
    elsif ($value =~ /^rgb\((\d+),(\d+),(\d+)\)$/) 
    {
        my ($r, $g, $b) = ($1, $2, $3);
        
        if ($main::args_restore_named_colors) 
        {
            my $clr_code = $b + (1 << 8) * $g + (1 << 16) * $r;
            my $named_color = Constants::color_from_code($clr_code);
            if (defined $named_color) {
                return $named_color;
            }
        }
        return sprintf('#%02x%02x%02x', $r, $g, $b);
    }
    else 
    {
        die "invalid color: '$value'";
    }
}

sub positiveFloat($) {
    my $value = shift;
    die "positive float value expected, but found: '$value'" unless ($value =~ /^\d+(\.\d+)?$/ && $value > 0);
    return $value;
}

sub nonnegativeFloat($) {
    my $value = shift;
    die "nonnegative float value expected, but found: '$value'" unless $value =~ /^\d+(\.\d+)?$/;
    return $value;
}

sub boolean($) {
    my $value = shift;
    die "boolean value expected, but found: '$value'" unless $value eq 'true' || $value eq 'false';
    return $value;
}

sub file_path($) {
    my $value = shift;
    return $value;
}

sub dashes($) {
    my $value = shift;
    my @dashes = ();
    for (split(',', $value)) {
        die unless /^\s*(\d+)\s*$/;
        push @dashes, $1;
    }
    return join ',', @dashes;
}

1;
