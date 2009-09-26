package T35;
use Object::Simple;

sub m1 : Translate { target => 'm1->m2->' }

Object::Simple->build_class;

