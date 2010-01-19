package T30;
use Object::Simple::Old(base => 'T30_Base1');

use T23;
use T31;

sub m1 : Translate { target => 'm2->m1' }
sub m2 : Attr { default => sub{ T23->new } }

sub m3 : Translate { target => 'm4->m2->m1' }
sub m4 : Attr { default => sub{ T31->new } }

sub m5 : Translate { target => 'm4->m5' }
sub m6 : Translate { target => 'm4->m6' }
sub m7 : Translate { target => 'm4->m7' }
sub m8 : Translate { target => 'm4->m8' }

Object::Simple::Old->build_class;
Object::Simple::Old->build_class;
