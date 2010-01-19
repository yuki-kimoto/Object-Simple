# undef value set
package T49;
use Object::Simple::Old;

sub m1 : HybridAttr { clone => 'scalar', build => 1 }
sub m2 : HybridAttr { clone => 'array', build => sub {['1', '2']} }
sub m3 : HybridAttr { clone => 'hash', build => sub {{a => 1, b => 2}} }
sub m4 : HybridAttr { clone => sub { $_[0] * 2 }, build => sub {3} }
sub m6 : HybridAttr { clone => 'scalar', build => 3 }
sub m8 : HybridAttr { clone => 'scalar' }
sub m9 : HybridAttr {
    type => 'hash',
    deref => 1, 
    clone   => 'hash',
    build => sub { {a => 1, b => 2} }
}

sub m10 : HybridAttr {
    type => 'array',
    deref => 1,
    clone   => 'array',
}

Object::Simple::Old->build_class;

package T49_2;
use base 'T49';

package T49_3;
use base 'T49_2';

package T49_4;
use base 'T49_3';



1;