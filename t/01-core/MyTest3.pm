# trigger
package MyTest3;
use Object::Simple;

sub w : Attr { }
sub x : Attr { trigger => sub{ $_->w( $_->x )  } }
sub y : Attr { trigger => sub{ $_[0]->w( $_[0]->y ) } }
sub z : Attr {
    trigger => [
        sub{ $_->w( $_->z ); },
        sub{ $_->w( $_->w * 2 ) }
    ]
}

Object::Simple->end;
