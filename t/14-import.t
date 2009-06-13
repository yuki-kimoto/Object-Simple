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
     ok( !$t->can( 'm3_1' ), 'mixin option passed as array ref 3-1' );
     ok( $t->can( 'm3_2' ), 'mixin option passed as array ref 3-2' );
     ok( !$t->can( 'm3_3' ), 'mixin option passed as array ref 3-3' );
     ok( $t->can( 'm3_4' ), 'mixin option passed as array ref 3-4' );
     ok( $t->can( 'm3_5' ), 'mixin option passed as array ref 3-5' );
     ok( !$t->can( 'm5_1' ), 'mixin option passed as array ref 5-1' );
     ok( $t->can( 'rename' ), 'mixin option passed as array ref rename' );
     ok( $t->can( 'm5_2' ), 'mixin option passed as array ref 5-2' );
     
}

eval "use T3";
like( $@, qr/Invalid import option 'a'/, 'Invalid import option' );

eval "use T4";
ok( $@, 'base not exist class' );

eval "use T5";
like( $@, qr/Invalid class name ';;;;'/, 'base invalid class name' );

eval "use T6";
ok($@, 'mixin not exist class' );

eval "use T7";
like($@, qr/mixin option must be key-value pairs/, 'method no exist' );

eval "use T8";
like($@, qr/Invalid class name /, 'invalid mixin class name');

eval "use T9";
like($@, qr/mixins must be array reference/, 'mixin must be array ref');

eval "use T10";
like($@, qr/mixins item must be class name or array reference/, 'mixin item is bad');

eval "use T11";
like($@, qr/methods is not exist in \@M2::EXPORT/, 'method is not exist in @EXPORT');

eval "use T12";
like($@, qr/mixin option 'n' is invalid/, 'invalid mixin options');

eval "use T13";
like($@, qr/Not exsits 'M6::m6_1/, 'Not exsits method');

eval "use T14";
like($@, qr/Fail M5 mixin rename/, 'fail rename');

{
    use T15;
    my $t = T15->new;
    can_ok($t, qw/m3_1 r3_2/);
}

eval "use T16";
like($@, qr/mixins select options must be array reference/, 'mixin select not array ref');
