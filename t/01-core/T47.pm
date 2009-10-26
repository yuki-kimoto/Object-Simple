# undef value set
package T47;
use Object::Simple;

sub m1 : ClassObjectAttr { initialize => {clone => 'scalar', default => 1} }
sub m2 : ClassObjectAttr { initialize => {clone => 'array', default => sub {['1', '2']} } }
sub m3 : ClassObjectAttr { initialize => {clone => 'hash', default => sub {{a => 1, b => 2}} } }
sub m4 : ClassObjectAttr { initialize => {clone => sub { $_[0] * 2 }, default => sub {3} } }
sub m6 : ClassObjectAttr { initialize => {clone => 'scalar', default => 3 } }
sub m8 : ClassObjectAttr { initialize => {clone => 'scalar' } }
sub m9 : ClassObjectAttr {
    type => 'hash',
    deref => 1, 
    initialize => {
        clone   => 'hash',
        default => sub { {a => 1, b => 2} }
    }
}

sub m10 : ClassObjectAttr {
    type => 'array',
    deref => 1,
    initialize => {
        clone   => 'array',
        default => sub { [1, 2] }
    }
}

Object::Simple->build_class;

package T47_2;
use base 'T47';

package T47_3;
use base 'T47_2';

package T47_4;
use base 'T47_3';



1;