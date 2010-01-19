package T20;
use Object::Simple::Old;

sub m1 : Attr { type => 'array'}
sub m2 : Attr { type => 'hash'}

Object::Simple::Old->build_class;
