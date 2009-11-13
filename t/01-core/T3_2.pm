package T3_2;
use Object::Simple;
sub m1 : Attr { default => 5 }
sub m2 : Attr { default => sub { 5 } }

Object::Simple->build_class;
