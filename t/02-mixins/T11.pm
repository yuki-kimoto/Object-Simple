package T11;
use Object::Simple( base => 'B2', mixins => ['M8', 'M9']);

sub m1 : Attr { default => 1 }


Object::Simple->build_class;
