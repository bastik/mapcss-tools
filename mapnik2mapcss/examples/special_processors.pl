{

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


# 06 landcover
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

# 07 landcover_line
register_special_processor(RuleProcessor->new('landcover_line',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('man_made', 'cutline'));
    }
));

# 12 glaciers-text
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

# 14 water_lines
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

#37 minor-roads-fill
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
register_special_processor(RuleProcessor->new('minor-roads-fill',
    sub {
        my $rule = shift;
        my $railtunnel = Conjunction->new([
            FilterCondition->new('railway', 'rail'),
            FilterCondition->new('tunnel', '#magic_yes'),
        ]);
        if ($railtunnel->equals($rule->filter)) {
            $rule->put_hint('flat', 1);
        }
        my $railnottunnel = Conjunction->new([
            FilterCondition->new('railway', 'rail'),
            FilterCondition->new('tunnel', '#magic_yes', '<>'),
        ]);
        if ($railnottunnel->equals($rule->filter)) {
            $rule->put_hint('under', 'casing');
        }
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
        $layer->set_z_index('directions', 15.0);
    }
));

#44 bridges_layer0
register_special_processor(LayerProcessor->new('bridges_layer0',
    sub {
        my $layer = shift;
        $layer->set_subpart('bridges_casing', 'bridge-casing1');
        $layer->set_z_index('bridges_casing', 2);
        $layer->set_subpart('bridges_casing2', 'bridge-casing2');
        $layer->set_z_index('bridges_casing2', 3);
        $layer->set_z_index('bridges_fill', 4);
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
        $layer->set_z_index('access', 7);
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
        $layer->set_z_index('directions', 15.0);
    }
));

#62 trams
register_special_processor(LayerProcessor->new('trams',
    sub {
        my $layer = shift;
        $layer->set_subpart('trams', 'tram');
        $layer->set_z_index('trams', 17);
    }
));
register_special_processor(RuleProcessor->new('trams',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
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

}
