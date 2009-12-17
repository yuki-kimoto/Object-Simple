# undef value set
package T1;
use Object::Simple;

sub a : Attr {}
sub b : Attr {}

Object::Simple->build_class;
