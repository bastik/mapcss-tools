{
    my $lancover_processor = sub {
        my $c = shift;
        if ($c->key eq 'religion' and $c->value eq 'INT-generic') {
            my $generic_religion = Conjunction->new([
                FilterCondition->new('religion', 'christian', '<>'), 
                FilterCondition->new('religion', 'jewish', '<>')
            ]);
            return $generic_religion;
        }
        return $c;
    };

    %special_processors = (
        'landcover' => $lancover_processor
    );
}
