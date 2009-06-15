package T30;
use Object::Simple;

use T23;
use T31;

sub m1 : Attr { translate => 'm2->m1' }
sub m2 : Attr { default => sub{ T23->new } }

sub m3 : Attr { translate => 'm4->m2->m1' }
sub m4 : Attr { default => sub{ T31->new } }

Object::Simple->build_class;
Object::Simple->build_class;
