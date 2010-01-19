package T49_Error1;
use Object::Simple::Old;
sub m5 : HybridAttr { clone => 'noexist' }

Object::Simple::Old->build_class;

