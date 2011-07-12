package PostgisDatasource;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %param = %{ shift(@_) };
    die unless $param{'type'} eq 'postgis';
    my $table = $param{'table'};
    die unless $table;
    my @types = ();
    while ($table =~ /planet_osm_([a-z]+)/g) {
        push @types, $1;
    }
    die 'could not detect database table' unless @types;
    die 'not supported' if @types > 1;
    if ($types[0] eq 'roads') {
        $types[0] = 'line';
    }
    my $self = {
        _basictype => $types[0],
    };
    bless $self, $class;
    return $self;
}

sub basictype {
    my $self = shift;
    return $self->{_basictype};
}

1;
