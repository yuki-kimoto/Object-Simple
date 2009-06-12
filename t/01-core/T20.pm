package T20;
use Object::Simple;

sub m1 : Attr { type => 'array'}
sub m2 : Attr { type => 'hash'}

Object::Simple->build_class;
