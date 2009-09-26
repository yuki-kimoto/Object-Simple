package T25;
use Object::Simple;

sub m1 : Attr { deref => 1 }

Object::Simple->build_class;
