package T22;
use Object::Simple::Old;

sub m1 : Attr { convert => 'T23'}
sub m2 : Attr { convert => sub{ return ($_[0] || 0 ) * 2 } }

Object::Simple::Old->build_class;
