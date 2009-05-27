package T10;
use Object::Simple;

sub m1 : Attr { weak => 1 }
sub m2 : Attr { default => { a => 1 } }

Object::Simple->end;
