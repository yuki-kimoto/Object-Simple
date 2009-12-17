package T3;
use Object::Simple;
sub x : Attr { default => sub{[1]} }

Object::Simple->build_class;
