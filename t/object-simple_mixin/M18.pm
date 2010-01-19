package M18;
use Object::Simple::Old;

sub m1 { die "" }
sub m2 { $_[0]->M18($_[1]) }


Object::Simple::Old->build_class;
