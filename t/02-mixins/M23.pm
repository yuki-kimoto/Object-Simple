package M23;
use Object::Simple;

sub m1 : ClassAttr { chained => 0 }
sub m2 : ClassAttr { chained => 0 }
sub m3 : ClassAttr { chained => 0 }

Object::Simple->build_class;
