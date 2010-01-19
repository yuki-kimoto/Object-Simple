package T47_Error3;
use Object::Simple::Old;
sub m1 : HybridAttr { initialize => {noexist => 1} }

Object::Simple::Old->build_class;
