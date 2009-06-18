package M18;
use Object::Simple;

sub m1 { die "" }
sub m2 { $_[0]->M18($_[1]) }


Object::Simple->build_class;
