package T16;
use Object::Simple::Old;

sub m1 : Attr {chained => 1}
sub m2 : Attr {weak => 1, chained =>1}
sub m3 : Attr {}
sub m4 : Attr { chained => 0 }

Object::Simple::Old->build_class;
