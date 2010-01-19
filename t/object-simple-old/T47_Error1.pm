package T47_Error1;
use Object::Simple::Old;
sub m5 : HybridAttr { initialize => {clone => 'noexist', default => sub {3} } }

Object::Simple::Old->build_class;

