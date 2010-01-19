package T17;
use Object::Simple::Old( mixins => ['M22', 'M23']);

sub m1 : ClassAttr { weak => 1 }


Object::Simple::Old->build_class;
