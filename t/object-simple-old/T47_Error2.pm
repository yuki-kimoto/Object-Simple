package T47_Error2;
use Object::Simple::Old;
sub m7 : HybridAttr { initialize => {clone => 'scalar', default => [] } }

Object::Simple::Old->build_class;
