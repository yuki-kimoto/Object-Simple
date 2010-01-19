# undef value set
package T46;
use Object::Simple::Old;

sub m1 : HybridAttr {type => 'array', deref => 1}
sub m2 : HybridAttr {auto_build => sub { shift->m2([5, 6]) }}


Object::Simple::Old->build_class;
