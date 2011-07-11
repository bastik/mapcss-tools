register_special_processor('landcover', 'condition-replace',
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
    });


register_special_processor('landcover_line', 'set-missing-filter',
    sub {
        return FilterCondition->new('man_made', 'cutline', '=');
    });

