use Test::More 'no_plan';
use strict;
use warnings;

use lib 't/14-import';

use T1;
{
    my $t = T1->new;
    ok( $t->can( 'b1' ), 'base option passed as string' );
    ok( $t->can( 'm1' ), 'mixin option passed as string' );
}

use T2;
{
     my $t = T2->new;
     ok( $t->can( 'b1' ), 'base option passed as array ref 1' );   

     ok( $t->can( 'm1' ), 'mixin option passed as array ref 1' );   
     ok( $t->can( 'm2' ), 'mixin option passed as array ref 2' );
     ok( $t->can( 'm3_1' ), 'mixin option passed as array ref 3-1' );
     ok( $t->can( 'm3_2' ), 'mixin option passed as array ref 3-2' );
     ok( $t->can( 'm3_3' ), 'mixin option passed as array ref 3-3' );
     ok( $t->can( 'm3_4' ), 'mixin option passed as array ref 3-4' );
     ok( $t->can( 'm3_5' ), 'mixin option passed as array ref 3-5' );
     ok( $t->can( 'm4_1' ), 'mixin option passed as array ref 4-1' );
     ok( !$t->can( 'm5_1' ), 'mixin option passed as array ref 5-1' );
     ok( $t->can( 'rename' ), 'mixin option passed as array ref rename' );
     ok( $t->can( 'm5_2' ), 'mixin option passed as array ref 5-2' );
     
     ok( $t->can( 'm6_1' ), 'mixin option expand tags 1' );
     ok( $t->can( 'm6_2' ), 'mixin option expand tags 2' );
     ok( $t->can( 'm6_3' ), 'mixin option expand tags 3' );
     ok( !$t->can( 'm6_4' ), 'mixin option expand tags 4' );
}

eval "use T3";
like( $@, qr/Invalid import option 'a'/, 'Invalid import option' );

eval "use T4";
ok( $@, 'base not exist class' );

eval "use T5";
like( $@, qr/Invalid class name ';;;;'/, 'base invalid class name' );

eval "use T6";
ok( $@, 'mixin not exist class' );

eval "use T7";
like( $@, qr/Not exsits 'M1::noexist'/, 'method no exist' );
