use Test::More tests => 2;
use strict;
use warnings;

package Book;
use Simo;

sub title{ ac }

package main;
# ac from class 
{
    eval{
        Book->title;
    };
    
    like( $@,
        qr/title must be called from object/,
        'accssor form class,not object'
    );
    
    my $book = Book->new( title => 1 );
    
    eval{
       Book->title;
    };
    
    like( $@,
        qr/title must be called from object/,
        'accssor form class,not object'
    );    
}