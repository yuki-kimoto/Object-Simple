package T47_Error4;
use Object::Simple;
sub m1 : HybridAttr { initialize => 'no_hash' }

Object::Simple->build_class;
