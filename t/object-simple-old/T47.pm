# undef value set
package T47;
use Object::Simple::Old;

sub m1 : HybridAttr { initialize => {clone => 'scalar', default => 1} }
sub m2 : HybridAttr { initialize => {clone => 'array', default => sub {['1', '2']} } }
sub m3 : HybridAttr { initialize => {clone => 'hash', default => sub {{a => 1, b => 2}} } }
sub m4 : HybridAttr { initialize => {clone => sub { $_[0] * 2 }, default => sub {3} } }
sub m6 : HybridAttr { initialize => {clone => 'scalar', default => 3 } }
sub m8 : HybridAttr { initialize => {clone => 'scalar' } }
sub m9 : HybridAttr {
    type => 'hash',
    deref => 1, 
    initialize => {
        clone   => 'hash',
        default => sub { {a => 1, b => 2} }
    }
}

sub m10 : HybridAttr {
    type => 'array',
    deref => 1,
    initialize => {
        clone   => 'array',
        default => sub { [1, 2] }
    }
}

Object::Simple::Old->build_class;

package T47_2;
use base 'T47';

package T47_3;
use base 'T47_2';

package T47_4;
use base 'T47_3';



1;