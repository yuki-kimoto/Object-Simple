package T25;
use Object::Simple::Old;

sub m1 : Attr { deref => 1 }

Object::Simple::Old->build_class;
