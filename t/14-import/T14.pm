package T14;
use Object::Simple(
    mixins => [
        ['M5', rename => { 'noexist' => 'aaa' }]
    ]
);

Object::Simple->end;
