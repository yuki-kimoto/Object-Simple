package T24;
use Object::Simple::Old;

sub m1 : Attr { type => 'array', deref => 1 }
sub m2 : Attr { type => 'hash',  deref => 1 }

Object::Simple::Old->build_class;
