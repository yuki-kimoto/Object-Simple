package T49_Error1;
use Object::Simple;
sub m5 : ClassObjectAttr { clone => 'noexist' }

Object::Simple->build_class;

