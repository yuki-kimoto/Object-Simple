package T11;
use Object::Simple::Old( base => 'B2', mixins => ['M8', 'M9']);

sub m1 : Attr { default => 1 }


Object::Simple::Old->build_class;
