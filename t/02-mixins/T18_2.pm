package T18_2;
use Object::Simple( mixins => ['T18_Mixin1']);

sub m1 : Attr {}

Object::Simple->build_class;
