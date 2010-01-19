package T10;
use Object::Simple::Old;

sub m1 : Attr { weak => 1 }
sub m2 : Attr { default => sub{{ a => 1 }} }

Object::Simple::Old->build_class;
