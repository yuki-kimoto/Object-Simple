package T1;
use Object::Simple( base => 'Book' );

sub m1  : Attr {default => 1}
sub m2 : Attr {default => 2}


Object::Simple->build_class;
