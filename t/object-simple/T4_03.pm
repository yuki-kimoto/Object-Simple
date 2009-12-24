package T4_03;
use Object::Simple( base => 'T5_03' );

sub m2  : Attr {default => 2}

Object::Simple->build_class;
