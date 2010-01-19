package T18_2;
use Object::Simple::Old( mixins => ['T18_Mixin1']);

sub m1 : Attr {}

Object::Simple::Old->build_class;
