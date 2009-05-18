# filter
package MyTest2;
use Object::Simple;

sub x : Attr { filter => sub{ $_ * 2  } }
sub y : Attr { filter => sub{ $_[0] * 2 } }
sub z : Attr {
    filter => [
        sub{ $_ * 2 },
        sub{ $_ * 2 }
    ]
}

Object::Simple->end;
