package T35;
use Object::Simple::Old;

sub m1 : Translate { target => 'm1->m2->' }

Object::Simple::Old->build_class;

