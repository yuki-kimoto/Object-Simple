package T3_2;
use Object::Simple::Old;
sub m1 : Attr { default => 5 }
sub m2 : Attr { default => sub { 5 } }

Object::Simple::Old->build_class;
