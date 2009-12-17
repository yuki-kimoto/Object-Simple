package T16;
use Object::Simple( mixins => ['M20', 'M21']);

sub m1 : ClassAttr { auto_build => sub {$_[0]->m1('T16-m1')} }


Object::Simple->build_class;
