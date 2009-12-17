package T34;
use Object::Simple;

sub m1 : Traslate { target => 'm1->2' }

Object::Simple->build_class;
