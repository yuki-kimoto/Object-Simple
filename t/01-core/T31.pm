package T31;
use Object::Simple;
use T23;

sub m1 : Attr { translate => 'm2->m1' }

sub m2 : Attr { default => sub{ T23->new } }

Object::Simple->build_class;
