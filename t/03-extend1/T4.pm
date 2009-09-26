package T4;
use Object::Simple( base => 'T5' );

sub m2  : Attr {default => 2}

Object::Simple->build_class;
