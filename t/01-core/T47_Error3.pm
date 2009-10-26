package T47_Error3;
use Object::Simple;
sub m1 : ClassObjectAttr { initialize => {noexist => 1} }

Object::Simple->build_class;
