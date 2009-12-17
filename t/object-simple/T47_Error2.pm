package T47_Error2;
use Object::Simple;
sub m7 : HybridAttr { initialize => {clone => 'scalar', default => [] } }

Object::Simple->build_class;
