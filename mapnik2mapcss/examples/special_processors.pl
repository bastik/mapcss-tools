{

my $tunnel = sub {
    my $cond = shift;
    if ($cond->key eq 'tunnel' and $cond->value eq 'yes') {
        $cond->set_value('#magic_yes');
    }
    return $cond;
};

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
        my $nobridge = FilterCondition->new('bridge', '#magic_yes');
        $nobridge->set_negated(1);
        $rule->set_filter(Conjunction->new([
                $rule->filter,
                $nobridge,
        ]));
    }
));

# 15 dam
register_special_processor(RuleProcessor->new('dam',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('waterway', 'dam'));
    }
));

# 17 piers-area
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

# 21 citywalls
register_special_processor(RuleProcessor->new('citywalls',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('historic', 'citywalls'));
    }
));

# 22 castle_walls
register_special_processor(RuleProcessor->new('castle_walls',
    sub {
        my $rule = shift;
        $rule->set_filter(FilterCondition->new('historic', 'castle_walls'));
    }
));

# 31 minor-roads-casing
register_special_processor(ConditionReplaceProcessor->new('minor-roads-casing', $tunnel));
register_special_processor(ConditionReplaceProcessor->new('minor-roads-casing',
    sub {
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
    }
));

#74 amenity-points
register_special_processor(RuleProcessor->new('amenity-points',
    sub {
        my $rule = shift;
        my $filter = $rule->filter;
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
