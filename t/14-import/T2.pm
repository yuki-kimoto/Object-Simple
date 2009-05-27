package T2;
use Object::Simple(
    base => 'B1',
    mixin => [
        'M1',
        'M2',
        { 'M3' => [ qw/m3_1 m3_2/ ] ,
          'M4' => 'm4_1' },
        { 'M5' => [ qw/m5_1=>rename m5_2/ ] },
        { 'M6' => [ qw/:tag1 m6_3/ ] },
        { 'M3' => [ qw/m3_2 m3_3/ ] },
        'M3'
    ]
);

Object::Simple->end;

