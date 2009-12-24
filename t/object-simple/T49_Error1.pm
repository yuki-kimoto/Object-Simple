package T49_Error1;
use Object::Simple;
sub m5 : HybridAttr { clone => 'noexist' }

Object::Simple->build_class;

