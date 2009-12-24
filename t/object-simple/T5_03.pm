package T5_03;
use Object::Simple( base => 'T6_03' );

sub m1  : Attr {default => 1}

Object::Simple->build_class;
