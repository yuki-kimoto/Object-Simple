package T7;
use Object::Simple(
    mixins => [
        ['M1', 'noexist']
    ] 
);

Object::Simple->end;