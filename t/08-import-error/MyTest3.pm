# trigger
package MyTest3;
use Object::Simple;

sub p : Attr { trigger => 'a' }
Object::Simple->end;
