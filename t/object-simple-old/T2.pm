package T2;
use Object::Simple::Old;

sub x : Attr { default => 1, read_only => 1 }

Object::Simple::Old->build_class;
