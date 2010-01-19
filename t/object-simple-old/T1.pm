# undef value set
package T1;
use Object::Simple::Old;

sub a : Attr {}
sub b : Attr {}

Object::Simple::Old->build_class;
