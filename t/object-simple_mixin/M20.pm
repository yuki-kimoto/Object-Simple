package M20;
use Object::Simple::Old;

sub m1 : ClassAttr { auto_build => sub {$_[0]->m1('M20-m1')} }
sub m2 : ClassAttr { auto_build => sub {$_[0]->m2('M20-m2')} }


Object::Simple::Old->build_class;
