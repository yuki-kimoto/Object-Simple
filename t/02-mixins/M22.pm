package M22;
use Object::Simple;

sub m1 : ClassAttr { read_only => 1 }
sub m2 : ClassAttr { read_only => 1 }


Object::Simple->build_class;
