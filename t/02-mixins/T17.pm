package T17;
use Object::Simple( mixins => ['M22', 'M23']);

sub m1 : ClassAttr { weak => 1 }


Object::Simple->build_class;
