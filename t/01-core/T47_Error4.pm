package T47_Error4;
use Object::Simple;
sub m1 : ClassObjectAttr { initialize => 'no_hash' }

Object::Simple->build_class;
