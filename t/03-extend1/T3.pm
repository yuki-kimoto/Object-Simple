package T3;
use Object::Simple(base => T2);

sub m3 : Attr{default => 3}

Object::Simple->end;

1;