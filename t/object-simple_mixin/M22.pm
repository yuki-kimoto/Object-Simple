package M22;
use Object::Simple::Old;

sub m1 : ClassAttr { read_only => 1 }
sub m2 : ClassAttr { read_only => 1 }


Object::Simple::Old->build_class;
