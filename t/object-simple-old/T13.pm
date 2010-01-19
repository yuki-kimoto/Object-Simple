package T13;
use Object::Simple::Old(base => 'T14');

sub title : Attr { default => 1 }

Object::Simple::Old->build_class;
