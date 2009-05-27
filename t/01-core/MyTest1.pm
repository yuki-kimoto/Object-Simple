# cnstrain
package MyTest1;
use Object::Simple;

sub x : Attr { type => sub{ $_[0] == 1 } }

sub q : Attr { type => sub{ 1 } };
sub r : Attr { type => sub{ 0 } };

Object::Simple->end;
