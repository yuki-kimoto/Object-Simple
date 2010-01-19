package Point;
use Object::Simple::Old;

sub x : Attr { default => 1 }
sub y : Attr { default => 1 }
sub z : Attr {}
sub p : Attr {default => sub{[1,2,3]}}

Object::Simple::Old->build_class;
