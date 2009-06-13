package T16;
use Object::Simple;

sub m1 : Attr {chained => 1}
sub m2 : Attr {weak => 1, chained =>1}

Object::Simple->build_class;
