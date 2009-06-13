package T5;
use Object::Simple( base => 'T6' );

sub m1  : Attr {default => 1}

Object::Simple->build_class;
