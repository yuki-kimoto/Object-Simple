package T2;
use Object::Simple::Old(
    mixins => [
        'M1',
        'M3',
    ]
);

Object::Simple::Old->build_class;

