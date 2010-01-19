package T47_Error4;
use Object::Simple::Old;
sub m1 : HybridAttr { initialize => 'no_hash' }

Object::Simple::Old->build_class;
