package Book;
use Object::Simple;

sub title : Attr {}
sub author : Attr {}
sub price : Attr { default => 1 }

Object::Simple->end;
