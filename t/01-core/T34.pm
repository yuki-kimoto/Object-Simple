package T34;
use Object::Simple;

sub m1 : Attr { translate => 'm1->2' }

Object::Simple->build_class;
