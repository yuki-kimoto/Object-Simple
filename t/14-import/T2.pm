package T2;
use Object::Simple(
    base => 'B1',
    mixins => [
        'M1',
        ['M3'],
        ['M5', rename => {'m5_1' => 'rename'}],
    ]
);

Object::Simple->end;

