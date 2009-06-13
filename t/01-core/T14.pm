package T14;
use Object::Simple;

sub title  : Attr { default => 2 }
sub author : Attr { default => 3 }

Object::Simple->build_class;
