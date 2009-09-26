package M15;
use Object::Simple(mixins => ['M16']);

sub m1 : Attr { default => 1 }

Object::Simple->build_class;
