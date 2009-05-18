package T7;
use Object::Simple( mixin => { 'M1' => 'noexist' } );

Object::Simple->end;
