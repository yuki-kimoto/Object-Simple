package T28;
use Object::Simple::Old;

sub m1 : Attr { trigger => 'a' }

Object::Simple::Old->build_class;
