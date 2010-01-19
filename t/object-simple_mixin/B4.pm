package B4;
use Object::Simple::Old(base => B5);

sub m1 { die "" }

sub m3 { $_[0]->B4($_[1]) }


Object::Simple::Old->build_class;

