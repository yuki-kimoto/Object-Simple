# filter
package MyTest2;
use Object::Simple;

sub p : Attr { filter => 'a' }

Object::Simple->end;
