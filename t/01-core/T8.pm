package T8;
use Object::Simple;

sub a1 : Attr { default => 1, setter_return => 'old' }
sub a2 : Attr { default => 1, setter_return => 'current' }
sub a3 : Attr { default => 1, setter_return => 'self' }
sub a5 : Attr { default => 1 }
sub a6 : Attr { default => 1, setter_return => 'undef' } 

Object::Simple->end;
