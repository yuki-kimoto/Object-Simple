package T18_Mixin1;
use Object::Simple::Old;

use T18_2;
sub m1 : Translate { target => 'm2->m1' }
sub m2 : Attr { default => sub { T18_2->new(m1 => 1) } }
sub m1_to : Output { target => 'm1' }


Object::Simple::Old->build_class;
