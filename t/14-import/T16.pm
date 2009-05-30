package T15;
use Object::Simple(
    mixins => [
        ['M3', select => 'aa']
    ]
);

Object::Simple->end;
