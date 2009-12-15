# undef value set
package T49;
use Object::Simple;

sub m1 : ClassObjectAttr { clone => 'scalar', build => 1 }
sub m2 : ClassObjectAttr { clone => 'array', build => sub {['1', '2']} }
sub m3 : ClassObjectAttr { clone => 'hash', build => sub {{a => 1, b => 2}} }
sub m4 : ClassObjectAttr { clone => sub { $_[0] * 2 }, build => sub {3} }
sub m6 : ClassObjectAttr { clone => 'scalar', build => 3 }
sub m8 : ClassObjectAttr { clone => 'scalar' }
sub m9 : ClassObjectAttr {
    type => 'hash',
    deref => 1, 
    clone   => 'hash',
    build => sub { {a => 1, b => 2} }
}

sub m10 : ClassObjectAttr {
    type => 'array',
    deref => 1,
    clone   => 'array',
}

Object::Simple->build_class;

package T49_2;
use base 'T49';

package T49_3;
use base 'T49_2';

package T49_4;
use base 'T49_3';



1;