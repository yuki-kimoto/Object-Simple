package T3;
use Object::Simple::Old;
sub x : Attr { default => sub{[1]} }

Object::Simple::Old->build_class;
