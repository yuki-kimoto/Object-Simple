package B2;
use Object::Simple::Old;

sub m1 : Attr { default => 100};
sub m4 : Attr { default => 10};

Object::Simple::Old->build_class;

