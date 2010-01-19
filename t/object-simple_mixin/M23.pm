package M23;
use Object::Simple::Old;

sub m1 : ClassAttr { chained => 0 }
sub m2 : ClassAttr { chained => 0 }
sub m3 : ClassAttr { chained => 0 }

Object::Simple::Old->build_class;
