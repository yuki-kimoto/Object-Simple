use Test::More 'no_plan';
use strict;
use warnings;

use lib 't/02-mixins';

use T1;
{
    my $t = T1->new;
    ok( $t->can( 'b1' ), 'base option passed as string' );
    ok( $t->can( 'm1' ), 'mixin option passed as string' );
    ok( !$t->can( 'm2' ), 'mixin only import method');
}

use T2;
{
     my $t = T2->new;
     ok( $t->can( 'm1' ), 'mixin option passed as array ref 1' );   
     ok( $t->can( 'm3_1' ), 'mixin option passed as array ref 3-1' );
     ok( $t->can( 'm3_2' ), 'mixin option passed as array ref 3-2' );
     ok( $t->can( 'm3_3' ), 'mixin option passed as array ref 3-3' );
     ok( $t->can( 'm3_4' ), 'mixin option passed as array ref 3-4' );
     ok( $t->can( 'm3_5' ), 'mixin option passed as array ref 3-5' );
}

eval "use T3";
like( $@, qr/Invalid import option 'a'/, 'Invalid import option' );

eval "use T4";
ok( $@, 'base not exist class' );

eval "use T5";
like( $@, qr/Invalid class name ';;;;'/, 'base invalid class name' );

eval "use T6";
ok($@, 'mixin not exist class' );

eval "use T8";
like($@, qr/Invalid class name /, 'invalid mixin class name');

eval "use T9";
like($@, qr/mixins must be array reference/, 'mixin must be array ref');

{
    use T11;
    my $t = T11->new;
    is_deeply( $t, {m1 => 3, m2 => 4, m3 => 5, m4 => 10}, 'mixins attr');
    
    is($t->m4, 2, 'override method');
    is($t->r4, 1, 'alias method');
}

{
    eval"use T12";
    like($@, qr/\Q'mixins_alias' must be hash reference/, 'mixins_alias is not hash ref');
}

{
    eval"use T13";
    like($@, qr/\Q'M8::m5' is undefined/, 'method is not defined');
}

{
    eval"use T14";
    like($@, qr/\Qalias '^^^' must be method_name/, 'method is not valid name');
}

