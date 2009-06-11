package T26;
use Object::Simple;

sub m1 : Attr { default => 3 }
sub m2 : Attr { alias => 'm1' }

Object::Simple->end;
