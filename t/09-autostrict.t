use Test::More tests => 1;

package Book;
use Object::Simple;

eval'$no_exist = 3;';

package main;

if( $@ ){
    pass();
}
else{
    fail( 'auto strict' );
}

