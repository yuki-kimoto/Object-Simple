package T2;
use Object::Simple(
    mixins => [
        'M1',
        'M3',
    ]
);

Object::Simple->build_class;

