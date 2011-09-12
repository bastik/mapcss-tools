use warnings;
use strict;

{

#### area z_index
my $area_offset = -1000;
my $water_areas_z_index =   $area_offset + 1;
my $water_areas_overlay_z_index = $area_offset + 2;
my $stadium_z_index =       $area_offset + 1;
my $leisure_track_z_index = $area_offset + 2;
my $leisure_pitch_z_index = $area_offset + 3;
my $buildings_z_index=      $area_offset + 100;

#### line z_index
my $line_offset = 0;
my $water_lines_casing_z_index =   $line_offset  + -1;
my $bridges_casing_z_index =       $line_offset  + 2;
my $bridges_casing2_z_index =      $line_offset  + 3;
my $bridges_fill_z_index =         $line_offset  + 4;
my $access_z_index =               $line_offset  + 7;
 # used both for bridges and !bridges
my $directions_z_index =           $line_offset  + 15;
my $tram_z_index =                 $line_offset  + 17;



my $tunnel = sub {
    my $cond = shift;
    if ($cond->key eq 'tunnel' and $cond->value eq 'yes') {
        $cond->set_value('#magic_yes');
    }
    return $cond;
};

my $oneway = sub {
    my $cond = shift;
    if ($cond->key eq 'oneway' and $cond->value eq 'yes') {
        $cond->set_value('#magic_yes');
    }
    return $cond;
};

my $int_minor = sub {
    my $cond = shift;
    if ($cond->key eq 'service' and $cond->value eq 'INT-minor') {
        my $intminor = Disjunction->new([
            FilterCondition->new('service', 'parking_aisle'), 
            FilterCondition->new('service', 'drive-through'), 
            FilterCondition->new('service', 'driveway')
        ]);
        $intminor->set_negated($cond->negated);
        return $intminor;
    }
    return $cond;
};

sub search_condition {
    my ($e, $test) = @_;
    if ($e->isa('FilterCondition')) 
    {
        return $test->applies($e);
    } 
    elsif ($e->isa('Junction')) 
    {
        for my $op (@{ $e->operands }) {
            if (search_condition->($op, $test)) {
                return 1;
            }
        }
        return 0;
    }
    else
    {
        die;
    }
    return 0;
}


#06 landcover
register_special_processor(ConditionReplaceProcessor->new('landcover',
    sub {
        my $cond = shift;
        if ($cond->key eq 'religion' and $cond->value eq 'INT-generic') {
            my $generic_religion = Conjunction->new([
                FilterCondition->new('religion', 'christian', '<>'), 
                FilterCondition->new('religion', 'jewish', '<>')
            ]);
            return $generic_religion;
        }
        return $cond;
    }
));

#07 landcover_line
register_special_processor(RuleProcessor->new('landcover_line',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('man_made', 'cutline'));
    }
));

#08 sports_grounds
my $stadium;
register_special_processor(RuleProcessor->new('sports_grounds',
    sub {
        my $rule = shift;
        unless (defined $stadium) {
            my $filterParser = new FilterParser();
            # line 3712
            $stadium = $filterParser->parse(
                "(([leisure]='sports_centre') or ([leisure]='stadium'))"
            );
        }
        if ($stadium->equals($rule->filter)) {
            $rule->put_hint('z-index', $stadium_z_index);
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'leisure' && $rule->filter->value eq 'track') {
            $rule->put_hint('z-index', $leisure_track_z_index);
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'leisure' && $rule->filter->value eq 'pitch') {
            $rule->put_hint('z-index', $leisure_pitch_z_index);
        }
    }
));

#09 water-lines-casing
register_special_processor(LayerProcessor->new('water-lines-casing',
    sub {
        my $layer = shift;
        $layer->set_subpart('water-lines-casing', 'water_lines-casing');
        $layer->set_z_index('water-lines-casing', $water_lines_casing_z_index);
    }
));
register_special_processor(RuleProcessor->new('water-lines-casing',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('tunnel', '#magic_yes', '<>'),
            ]),
        ]));
    }
));

#10 water_areas
register_special_processor(LayerProcessor->new('water_areas',
    sub {
        my $layer = shift;
        $layer->set_z_index('water_areas', $water_areas_z_index);
    }
));

#11 water-areas-overlay
register_special_processor(LayerProcessor->new('water-areas-overlay',
    sub {
        my $layer = shift;
        $layer->set_z_index('water-areas-overlay', $water_areas_overlay_z_index);
    }
));

#12 glaciers-text
register_special_processor(RuleProcessor->new('glaciers-text',
    sub {
        my $rule = shift;
        my $glacier = FilterCondition->new('natural', 'glacier');
        $rule->set_filter(Conjunction->new([
                $glacier,
                $rule->filter,
        ]));
    }
));

#14 water_lines
register_special_processor(ConditionReplaceProcessor->new('water_lines', $tunnel));
register_special_processor(RuleProcessor->new('water_lines',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
                $rule->filter,
                FilterCondition->new('bridge', '#magic_yes', '<>'),
                FilterCondition->new('bridge', 'aqueduct', '<>'),
        ]));
    }
));

#15 dam
register_special_processor(RuleProcessor->new('dam',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('waterway', 'dam'));
    }
));

#16 marinas-area
register_special_processor(RuleProcessor->new('marinas-area',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('leisure', 'marina'));
    }
));

#17 piers-area
register_special_processor(RuleProcessor->new('piers-area',
    sub {
        my $rule = shift;
        $rule->set_filter(Disjunction->new([
                FilterCondition->new('man_made', 'pier'),
                FilterCondition->new('man_made', 'breakwater'),
                FilterCondition->new('man_made', 'groyne')
        ]));
    }
));

#21 citywalls
register_special_processor(RuleProcessor->new('citywalls',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('historic', 'citywalls'));
    }
));

#22 castle_walls
register_special_processor(RuleProcessor->new('castle_walls',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('historic', 'castle_walls'));
    }
));

#25 turning_circle-casing
register_special_processor(LayerProcessor->new('turning_circle-casing',
    sub {
        my $layer = shift;
        $layer->set_subpart('turning_circle-casing', 'turning_circle-casing');
        $layer->set_z_index('turning_circle-casing', -1);
    }
));
register_special_processor(ConditionReplaceProcessor->new('turning_circle-casing',
    sub {
        my $cond = shift;
        if ($cond->key eq 'int_tc_type') {
            $cond->set_key('highway');
        }
        return $cond;
    }
));
register_special_processor(RuleProcessor->new('turning_circle-casing',
    sub {
        my $rule = shift;
        $rule->put_hint('join', 'node');
        $rule->put_hint('concat', sub {
            my ($basic_selector, $zoom, $conditions, $closed, $layer) =  @_;
            return "way${conditions} > ${basic_selector}${zoom}[highway=turning_circle]${closed}${layer}";
        });
    }
));

#26 footbikecycle-tunnels
register_special_processor(RuleProcessor->new('footbikecycle-tunnels',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            FilterCondition->new('tunnel', '#magic_yes'),
        ]));
        $rule->put_hint('under', 'under');
    }
));

#27 tracks-tunnels
register_special_processor(RuleProcessor->new('tracks-tunnels',
    sub {
        my $rule = shift;
        if ($rule->filter eq 'ElseFilter') {
            $rule->set_filter(Conjunction->new([
                FilterCondition->new('tracktype', 'grade1', '<>'),
                FilterCondition->new('tracktype', 'grade2', '<>'),
                FilterCondition->new('tracktype', 'grade3', '<>'),
                FilterCondition->new('tracktype', 'grade4', '<>'),
                FilterCondition->new('tracktype', 'grade5', '<>'),
            ])); 
        }
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            FilterCondition->new('tunnel', '#magic_yes'),
        ]));
        $rule->put_hint('under', 'under');
    }
));

#30 highway-area-casing
if ($main::area_closed_josm_hint) {
    register_special_processor(RuleProcessor->new('highway-area-casing',
        sub {
            my $rule = shift;
            $rule->put_hint('closed', 1);
        }
    ));
}

#31 minor-roads-casing
register_special_processor(LayerProcessor->new('minor-roads-casing',
    sub {
        my $layer = shift;
        $layer->set_subpart('minor-roads-casing-links', 'roads-casing');
        $layer->set_subpart('minor-roads-casing', 'roads-casing');
        $layer->set_z_index('minor-roads-casing-links', -1);
        $layer->set_z_index('minor-roads-casing', -1);
    }
));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-casing', $tunnel));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-casing', $int_minor));

#32 highway-area-fill
if ($main::area_closed_josm_hint) {
    register_special_processor(RuleProcessor->new('highway-area-fill',
        sub {
            my $rule = shift;
            $rule->put_hint('closed', 1);
        }
    ));
}

#34 buildings
register_special_processor(RuleProcessor->new('buildings',
    sub {
        my $rule = shift;
        $rule->put_hint('z-index', $buildings_z_index);
        
        return if ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'aeroway' && $rule->filter->value eq 'terminal');

        my $has_pos_building = 0; # is there a condion [building=*] ?
        my $search_rec;
        $search_rec = sub {
            my $e = shift;
            if ($e->isa('FilterCondition')) 
            {
                if ($e->key eq 'building' && !$e->negated) {
                    $has_pos_building = 1;
                }
            } 
            elsif ($e->isa('Junction')) 
            {
                for my $op (@{ $e->operands }) {
                    $search_rec->($op);
                }
            }
            else
            {
                die;
            }
        };
        $search_rec->($rule->filter);
        
        if ($has_pos_building) {
            $rule->set_filter(Conjunction->new([
                $rule->filter,
                FilterCondition->new('railway', 'station', '<>'),
                FilterCondition->new('amenity', 'place_of_worship', '<>'),
            ]));
        } else {
            $rule->set_filter(Conjunction->new([
                $rule->filter,
                FilterCondition->new('building', 'no', '<>'),
                FilterCondition->new('building', 'station', '<>'),
                FilterCondition->new('building', 'supermarket', '<>'),
                FilterCondition->new('railway', 'station', '<>'),
                FilterCondition->new('amenity', 'place_of_worship', '<>'),
            ]));
        }
    }
));
register_special_processor(ConditionReplaceProcessor->new('buildings',
    sub {
        my $cond = shift;
        if ($cond->key eq 'building' and $cond->value eq 'INT-light') {
            my $light = Disjunction->new([
                FilterCondition->new('building', 'residential'),
                FilterCondition->new('building', 'house'),
                FilterCondition->new('building', 'garage'),
                FilterCondition->new('building', 'garages'),
                FilterCondition->new('building', 'detached'),
                FilterCondition->new('building', 'terrace'),
                FilterCondition->new('building', 'apartments'),
            ]);
            $light->set_negated($cond->negated);
            return $light;
        }
        return $cond;
    }
));

#35 turning_circle-fill
register_special_processor(ConditionReplaceProcessor->new('turning_circle-fill',
    sub {
        my $cond = shift;
        if ($cond->key eq 'int_tc_type') {
            $cond->set_key('highway');
        }
        return $cond;
    }
));
register_special_processor(RuleProcessor->new('turning_circle-fill',
    sub {
        my $rule = shift;
        $rule->put_hint('join', 'node');
        $rule->put_hint('concat', sub {
            my ($basic_selector, $zoom, $conditions, $closed, $layer) =  @_;
            return "way${conditions} > ${basic_selector}${zoom}[highway=turning_circle]${closed}${layer}";
        });
    }
));

#36 tracks-notunnel-nobridge
register_special_processor(RuleProcessor->new('tracks-notunnel-nobridge',
    sub {
        my $rule = shift;
        $rule->put_hint('under', 'casing');
        
        if ($rule->filter eq 'ElseFilter') {
            $rule->set_filter(Conjunction->new([
                FilterCondition->new('tracktype', 'grade1', '<>'),
                FilterCondition->new('tracktype', 'grade2', '<>'),
                FilterCondition->new('tracktype', 'grade3', '<>'),
                FilterCondition->new('tracktype', 'grade4', '<>'),
                FilterCondition->new('tracktype', 'grade5', '<>'),
            ])); 
        }
        
        $rule->set_filter(Conjunction->new([
            FilterCondition->new('highway', 'track'),
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('bridge', ''),
                FilterCondition->new('bridge', 'no'),
                # according to taginfo, bridge=false is not used at all
                # so reduce complexity a bit                
                #FilterCondition->new('bridge', 'false'),
            ]),
            Disjunction->new([
                FilterCondition->new('tunnel', ''),
                FilterCondition->new('tunnel', 'no'),
                # tunnel=false isn't used at all either
                #FilterCondition->new('tunnel', 'false'),
            ]),
        ]));
    }
));

#37 minor-roads-fill
my ($rail_tunnel, $rail_not_tunnel, $spur_tunnel, $narrow_gauge_tunnel);
register_special_processor(RuleProcessor->new('minor-roads-fill',
    sub {
        my $rule = shift;
        unless (defined $rail_tunnel) {
            my $filterParser = new FilterParser();
            # line 3712
            $rail_tunnel = $filterParser->parse(
                "(([railway]='rail') and ([tunnel]='yes'))"
            );
            # line 3768, 3783
            $rail_not_tunnel = $filterParser->parse(
                "(([railway]='rail') and not (([tunnel]='yes')))"
            );
            # line 3806
            $spur_tunnel = $filterParser->parse(
                "(([railway]='spur-siding-yard') and ([tunnel]='yes'))"
            );
            # line 3875
            $narrow_gauge_tunnel = $filterParser->parse(
                "((([railway]='narrow_gauge') or ([railway]='funicular')) and ([tunnel]='yes'))"
            );
        }
        if ($rail_tunnel->equals($rule->filter)) {
            $rule->put_hint('flat', 1);
        }
        if ($rail_not_tunnel->equals($rule->filter)) {
            $rule->put_hint('under', 'casing');
        }
        if ($spur_tunnel->equals($rule->filter)) {
            $rule->put_hint('flat', '1');
        }
        if ($narrow_gauge_tunnel->equals($rule->filter)) {
            $rule->put_hint('under', 'casing');
        }
    }
));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-fill', $tunnel));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-fill', $int_minor));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-fill',
    sub {
        my $cond = shift;
        if ($cond->key eq 'railway' and $cond->value eq 'spur-siding-yard') {
            return Disjunction->new([
                FilterCondition->new('railway', 'spur'),
                FilterCondition->new('railway', 'siding'),
                Conjunction->new([
                    FilterCondition->new('railway', 'rail'),
                    Disjunction->new([
                        FilterCondition->new('service', 'spur'),
                        FilterCondition->new('service', 'siding'),
                        FilterCondition->new('service', 'yard'),
                    ]),
                ]),
            ]);
        }
        return $cond;
    }
));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-fill',
    sub {
        my $cond = shift;
        if ($cond->key eq 'bridge' and $cond->value eq 'yes') {
            my $bridge = Disjunction->new([
                FilterCondition->new('bridge', '#magic_yes'),
                FilterCondition->new('bridge', 'viaduct'),
            ]);
            $bridge->set_negated($cond->negated);
            return $bridge;
        }
        return $cond;
    }
));

#38 ferry-routes
register_special_processor(RuleProcessor->new('ferry-routes',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('route', 'ferry'));
    }
));

#40 roads
register_special_processor(ConditionReplaceProcessor->new('roads', $tunnel));
register_special_processor(ConditionReplaceProcessor->new('roads',
    sub {
        my $cond = shift;
        if ($cond->key eq 'railway' and $cond->value eq 'INT-preserved-ssy') {
            return Conjunction->new([
                FilterCondition->new('railway', 'preserved'),
                Disjunction->new([
                    FilterCondition->new('service', 'spur'),
                    FilterCondition->new('service', 'siding'),
                    FilterCondition->new('service', 'yard'),
                ]),
            ]);
        } elsif ($cond->key eq 'railway') {# and !($cond->value eq 'preserved')) {
            return Conjunction->new([
                $cond,
                FilterCondition->new('service', 'spur', '<>'),
                FilterCondition->new('service', 'siding', '<>'),
                FilterCondition->new('service', 'yard', '<>'),
            ]);
        
        }
        return $cond;
    }
));

#41 waterway-bridges
register_special_processor(RuleProcessor->new('waterway-bridges',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
                FilterCondition->new('waterway', 'canal'),
                Disjunction->new([
                    FilterCondition->new('bridge', '#magic_yes'),
                    FilterCondition->new('bridge', 'aqueduct'),
                ]),
        ]));
    }
));

#42 access-pre_bridges
register_special_processor(ConditionReplaceProcessor->new('access-pre_bridges', $int_minor));
register_special_processor(RuleProcessor->new('access-pre_bridges',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
                $rule->filter,
                FilterCondition->new('bridge', '#magic_yes', '<>'),
                FilterCondition->new('bridge', 'viaduct', '<>'),
        ]));
    }
));

#43 direction_pre_bridges         
register_special_processor(ConditionReplaceProcessor->new('direction_pre_bridges', $oneway));
register_special_processor(RuleProcessor->new('direction_pre_bridges',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('highway', '', '<>'),
                FilterCondition->new('railway', '', '<>'),
                FilterCondition->new('waterway', '', '<>'),
            ]),
            FilterCondition->new('bridge', '#magic_yes', '<>'),
            FilterCondition->new('bridge', 'viaduct', '<>'),
        ]));
    }
));
register_special_processor(LayerProcessor->new('direction_pre_bridges',
    sub {
        my $layer = shift;
        $layer->set_subpart('directions', 'oneway');
        $layer->set_z_index('directions', $directions_z_index);
    }
));

#44 bridges_layer0
register_special_processor(LayerProcessor->new('bridges_layer0',
    sub {
        my $layer = shift;
        $layer->set_subpart('bridges_casing', 'bridge-casing1');
        $layer->set_z_index('bridges_casing', $bridges_casing_z_index);
        $layer->set_subpart('bridges_casing2', 'bridge-casing2');
        $layer->set_z_index('bridges_casing2', $bridges_casing2_z_index);
        $layer->set_z_index('bridges_fill', $bridges_fill_z_index);
    }
));
register_special_processor(ConditionReplaceProcessor->new('bridges_layer0',
    sub {
        my $cond = shift;
        if ($cond->key eq 'railway' and $cond->value eq 'INT-spur-siding-yard') {
            return Disjunction->new([
                FilterCondition->new('railway', 'spur'),
                FilterCondition->new('railway', 'siding'),
                Conjunction->new([
                    FilterCondition->new('railway', 'rail'),
                    Disjunction->new([
                        FilterCondition->new('service', 'spur'),
                        FilterCondition->new('service', 'siding'),
                        FilterCondition->new('service', 'yard'),
                    ]),
                ]),
            ]);
        }
        return $cond;
    }
));
register_special_processor(RuleProcessor->new('bridges_layer0',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('bridge', '#magic_yes'),
                FilterCondition->new('bridge', 'viaduct'),
            ]),
#            Disjunction->new([
#                FilterCondition->new('layer', ''),
#                FilterCondition->new('layer', '0'),
#            ]),
        ]));
    }
));

#45 bridges_access0
register_special_processor(LayerProcessor->new('bridges_access0',
    sub {
        my $layer = shift;
        $layer->set_subpart('access', 'access');
        $layer->set_z_index('access', $access_z_index);
    }
));
register_special_processor(ConditionReplaceProcessor->new('bridges_access0', $int_minor));
register_special_processor(RuleProcessor->new('bridges_access0',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('bridge', '#magic_yes'),
                FilterCondition->new('bridge', 'viaduct'),
            ]),
#            FilterCondition->new('layer', '0', '<='),
        ]));
    }
));

#46 bridges_directions0
register_special_processor(ConditionReplaceProcessor->new('bridges_directions0', $oneway));
register_special_processor(RuleProcessor->new('bridges_directions0',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            Disjunction->new([
                FilterCondition->new('highway', '', '<>'),
                FilterCondition->new('railway', '', '<>'),
                FilterCondition->new('waterway', '', '<>'),
            ]),
            Disjunction->new([
                FilterCondition->new('bridge', '#magic_yes', '<>'),
                FilterCondition->new('bridge', 'viaduct', '<>'),
            ]),
        ]));
    }
));
register_special_processor(LayerProcessor->new('bridges_directions0',
    sub {
        my $layer = shift;
        $layer->set_subpart('directions', 'oneway');
        $layer->set_z_index('directions', $directions_z_index);
    }
));

#62 trams
register_special_processor(LayerProcessor->new('trams',
    sub {
        my $layer = shift;
        $layer->set_subpart('trams', 'tram');
        $layer->set_z_index('trams', $tram_z_index);
    }
));
register_special_processor(RuleProcessor->new('trams',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            FilterCondition->new('tunnel', '#magic_yes', '<>'),
        ]));
    }
));
register_special_processor(RuleProcessor->new('trams',
    sub {
        my $rule = shift;
        $rule->put_hint('under', 'under');
    }
));

#63 guideways
register_special_processor(RuleProcessor->new('guideways',
    sub {
        my $rule = shift;

        $rule->put_hint('under', 'casing');

        $rule->set_filter(Conjunction->new([
            FilterCondition->new('highway', 'bus_guideway'),
            FilterCondition->new('tunnel', '#magic_yes', '<>'),
        ]));
    }
));

#66 admin-other
register_special_processor(RuleProcessor->new('admin-other',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        if ($filter->isa('FilterCondition') &&
                $filter->key eq 'admin_level' && 
                $filter->value eq '') 
        {
            $rule->set_filter(Conjunction->new([
                $filter,
                FilterCondition->new('admin_level', '8', '>'),
            ]));
        }
    }
));


#68 placenames-capital
register_special_processor(RuleProcessor->new('placenames-capital',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
            Disjunction->new([
                FilterCondition->new('place', 'city'),
                FilterCondition->new('place', 'metropolis'),
                FilterCondition->new('place', 'town'),
            ]),
            FilterCondition->new('captial', '#magic_yes'),
        ]));
    }
));

#69 placenames-medium
register_special_processor(RuleProcessor->new('placenames-medium',
    sub {
        my $rule = shift;
        $rule->set_filter(Conjunction->new([
            $rule->filter,
            FilterCondition->new('captial', '#magic_yes', '<>'),
        ]));
    }
));

my ($railway1, $railway2);
sub amenity_stations {
    my $rule = shift;
    my $h = 6;
    unless (defined $railway1) {
        my $filterParser = new FilterParser();
        $railway1 = $filterParser->parse(
            "((([railway]='halt') or ([railway]='tram_stop')) or ([aerialway]='station'))"
        );
        $railway2 = $filterParser->parse(
            "(([railway]='station') and not (([disused]='yes')))"
        );
    }
    
    if ($railway1->equals($rule->filter)) {
        if ($rule->maxzoom && $rule->maxzoom == 15) { # |z15-
            $h = 6;
        } else {
            $h = 4;
        }
    }
    elsif ($railway2->equals($rule->filter)) {
        if ($rule->maxzoom && $rule->maxzoom == 15) { # |z15-
            $h = 9;
        } else {
            $h = 6;
        }
    }
    
    $rule->put_hint('icon-height', $h);
}

#71 amenity-stations
register_special_processor(RuleProcessor->new('amenity-stations', \&amenity_stations));

#72 amenity-stations-poly
register_special_processor(RuleProcessor->new('amenity-stations-poly', \&amenity_stations));

sub icon_height16 {
    my $rule = shift;
    $rule->put_hint('icon-height', 16);
}

#73 amenity-symbols
register_special_processor(RuleProcessor->new('amenity-symbols', \&icon_height16));

#74 amenity-symbols-poly
register_special_processor(RuleProcessor->new('amenity-symbols-poly', \&icon_height16));

#74 amenity-points
register_special_processor(RuleProcessor->new('amenity-points',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
        # don't replace amenity=place_of_worship in general - just
        # when it is the only condition in a filter
        if ($filter->isa('FilterCondition')) {
            if ($filter->key eq 'amenity' && $filter->value eq 'place_of_worship') {
                $rule->set_filter(Conjunction->new([
                    $filter,
                    FilterCondition->new('religion', 'christian', '<>'), 
                    FilterCondition->new('religion', 'muslim', '<>'), 
                    FilterCondition->new('religion', 'sikh', '<>'), 
                    FilterCondition->new('religion', 'jewish', '<>'), 
                ]));
            }
        }
    }
));

#77 power_line
register_special_processor(RuleProcessor->new('power_line',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('power', 'line'));
    }
));

#78 power_minorline
register_special_processor(RuleProcessor->new('power_minorline',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('power', 'minor_line'));
    }
));

#79 power_towers
register_special_processor(RuleProcessor->new('power_towers',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('power', 'tower'));
    }
));

#80 power_poles
register_special_processor(RuleProcessor->new('power_poles',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('power', 'pole'));
    }
));

#82 highway-junctions
register_special_processor(RuleProcessor->new('highway-junctions',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('highway', 'motorway_junction'));
        $rule->put_hint('icon-height', 8);
    }
));

#83 planet roads text osm
register_special_processor(RuleProcessor->new('planet roads text osm',
    sub {
        my $rule = shift;
        if ($rule->filter eq 'ElseFilter') {
            $rule->set_filter(Disjunction->new([
                Conjunction->new([
                    FilterCondition->new('highway', '', '<>'),
                    FilterCondition->new('highway', 'motorway', '<>'),
                    FilterCondition->new('highway', 'trunk', '<>'),
                    FilterCondition->new('highway', 'primary', '<>'),
                    FilterCondition->new('highway', 'secondary', '<>'),
                    FilterCondition->new('highway', 'tertiary', '<>'),
                    FilterCondition->new('highway', 'unclassified', '<>'),
                    FilterCondition->new('highway', 'residential', '<>'),
                    FilterCondition->new('highway', 'proposed', '<>'),
                    FilterCondition->new('highway', 'construction', '<>'),
                ]),
                Conjunction->new([
                    FilterCondition->new('aeroway', '', '<>'),
                    FilterCondition->new('aeroway', 'runway', '<>'),
                    FilterCondition->new('aeroway', 'taxiway', '<>'),
                ]),
            ]));
        }
    }
));
register_special_processor(ConditionReplaceProcessor->new('planet roads text osm',
    sub {
        my $cond = shift;
        if ($cond->key eq 'bridge' and $cond->value eq 'yes') {
            $cond->set_value('#magic_yes');
        }
        return $cond;
    }
));

#84 text
my ($amenity1, $historic1, $tourism1);
register_special_processor(RuleProcessor->new('text',
    sub {
        my $rule = shift;
        my $h = 16;
        unless (defined $amenity1) {
            my $filterParser = new FilterParser();
            $amenity1 = $filterParser->parse(
                "((([amenity]='library') or ([amenity]='theatre')) or ([amenity]='courthouse'))"
            );
            $historic1 = $filterParser->parse(
                "(([historic]='memorial') or ([historic]='archaeological_site'))"
            );
            $tourism1 = $filterParser->parse(
                "((([tourism]='hotel') or ([tourism]='hostel')) or ([tourism]='chalet'))"
            );
        }
        
        if ($amenity1->equals($rule->filter)) {
            $h = 20;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'amenity' && $rule->filter->value eq 'bar') {
            $h = 20;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'amenity' && $rule->filter->value eq 'cinema') {
            $h = 24;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'amenity' && $rule->filter->value eq 'cinema') {
            $h = 24;
        }
        elsif ($historic1->equals($rule->filter)) {
            $h = 20; #FIXME
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'natural' && $rule->filter->value eq 'spring') {
            $h = 7;
        }
        elsif ($tourism1->equals($rule->filter)) {
            $h = 20; #FIXME
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'amenity' && $rule->filter->value eq 'embassy') {
            $h = 12;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'tourism' && $rule->filter->value eq 'bed_and_breakfast') {
            $h = 20;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'tourism' && $rule->filter->value eq 'caravan_site') {
            $h = 24;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'waterway' && $rule->filter->value eq 'lock') {
            $h = 9;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'amenity' && $rule->filter->value eq 'prison') {
            $h = 20;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'man_made' && $rule->filter->value eq 'lighthouse') {
            $h = 20;
        }
        elsif ($rule->filter->isa('FilterCondition') && $rule->filter->key eq 'man_made' && $rule->filter->value eq 'windmill') {
            $h = 15;
        }
        
        $rule->put_hint('icon-height', $h);
    }
));


#87 interpolation_lines
register_special_processor(RuleProcessor->new('interpolation_lines',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('addr:interpolation', '', '<>'));
    }
));

#88 housenumbers
register_special_processor(RuleProcessor->new('housenumbers',
    sub {
        my $rule = shift;
        $rule->put_hint('join', 'node');
        # somewhat hacky
        $rule->put_hint('concat', sub {
            my ($basic_selector, $zoom, $conditions, $closed, $layer) =  @_;
            return "node${zoom}${conditions}${closed}${layer},\n"
                  ."area${zoom}${conditions}${closed}${layer}";
        });
       $rule->set_filter(FilterCondition->new('addr:housenumber', '', '<>'));
    }
));

#90 misc_boundaries
register_special_processor(RuleProcessor->new('misc_boundaries',
    sub {
        my $rule = shift;
        if ($rule->filter) {
            $rule->set_filter(Conjunction->new([
                $rule->filter,
                FilterCondition->new('boundary', 'national_park'),
            ]));
        } else {
            $rule->set_filter(FilterCondition->new('boundary', 'national_park'));
        }
    }
));

}
