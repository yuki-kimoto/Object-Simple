package T2;
use Object::Simple;

sub x : Attr { default => 1, read_only => 1 }

Object::Simple->end;
