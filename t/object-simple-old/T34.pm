package T34;
use Object::Simple::Old;

sub m1 : Traslate { target => 'm1->2' }

Object::Simple::Old->build_class;
