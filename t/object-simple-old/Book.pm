package Book;
use Object::Simple::Old;

sub title : Attr {}
sub author : Attr {}
sub price : Attr { default => 1 }

Object::Simple::Old->build_class('Book');
