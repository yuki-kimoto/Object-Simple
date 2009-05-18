use strict;
use warnings;
use Test::More tests => 6;


package Book1;
use Simo;

sub title{ ac 1 }


package Book2;
use Simo;

sub author{ ac 2 }

package Book3;
use base qw( Book1 Book2 );


package main;
use strict;
use warnings;
{
    my $book = Book3->new;


    is( $book->title, 1, 'multi extends left' );
    is( $book->author, 2, 'multi extends right' );

    is( $book->title, 1, 'multi extends left second' );
    is( $book->author, 2, 'multi extends right second' );
}

package Book4;
use Simo;
sub title{ ac 1  }
sub author{ ac 3  }

package Book5;
use Simo;
sub title{ ac 2 }

package Book6;
use base qw( Book4 Book5 );

package main;

{ 
    my $book = Book6->new;
    is( $book->title, 1, "dual method select left" );
}

package Book7;
use base qw( Book4 );


package Book8;
use Simo;
sub author{ ac 4 };

package Book9;
use base qw( Book7 Book8 );

package main;
{
    my $book = Book9->new;
    is( $book->author, 3 , "2 layler select left" );
}

__END__