package T28;
use Object::Simple;

sub m1 : Attr { trigger => 'a' }

Object::Simple->build_class;
