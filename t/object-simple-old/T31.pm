package T31;
use Object::Simple::Old;
use T23;

sub m1 : Attr { translate => 'm2->m1' }
sub m2 : Attr { default => sub{ T23->new } }

sub m5 : Attr {}
sub m6 : Attr { chained => 0 }

sub m7 : Attr { type => 'array', deref => 1 }
sub m8 : Attr { type => 'hash',  deref => 1 }

Object::Simple::Old->build_class;
