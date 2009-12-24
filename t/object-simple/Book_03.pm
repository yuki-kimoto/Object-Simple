package Book_03;
use Object::Simple;

sub title : Attr { default => 1 }

Object::Simple->build_class;

