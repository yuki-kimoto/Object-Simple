package T48_Error1;
use Object::Simple;

sub m1 : Attr { build => [] }

Object::Simple->build_class;
