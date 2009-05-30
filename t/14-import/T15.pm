package T15;
use Object::Simple(
    mixins => [
        ['M3', select => [qw/m3_1 m3_2/], rename => { m3_2 => r3_2 }]
    ]
);

Object::Simple->end;
