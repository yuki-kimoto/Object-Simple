package T47_Error1;
use Object::Simple;
sub m5 : HybridAttr { initialize => {clone => 'noexist', default => sub {3} } }

Object::Simple->build_class;

