package T48_Error1;
use Object::Simple::Old;

sub m1 : Attr { build => [] }

Object::Simple::Old->build_class;
