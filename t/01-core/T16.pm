package T16;
use Object::Simple;

sub m1 : Attr {chained => 1}
sub m2 : Attr {weak => 1, chained =>1}
sub m3 : Attr {}
sub m4 : Attr { chained => 0 }

Object::Simple->build_class;
