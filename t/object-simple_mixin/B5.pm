package B5;
use Object::Simple::Old;

sub m1 { die "" }

sub m3 { die "" }
sub m4 { $_[0]->B5($_[1]) }

Object::Simple::Old->build_class;

