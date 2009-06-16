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
like( $@, qr/\Q'a' is invalid import option (T3)/, 'Invalid import option' );

eval "use T4";
ok( $@, 'base not exist class' );

eval "use T5";
like( $@, qr/\QBase class ';;;;' is invalid class name (T5)/, 'base invalid class name' );

eval "use T6";
ok($@, 'mixin not exist class' );

eval "use T8";
like($@, qr/\QMixin class '()()(' is invalid class name (T8)/, 'invalid mixin class name');

eval "use T9";
like($@, qr/mixins must be array reference/, 'mixin must be array ref');

{
    use T11;
    my $t = T11->new;
    is_deeply( $t, {m1 => 1, m2 => 4, m3 => 2, m4 => 2, m5 => 5}, 'mixins attr');
}

{
    use T12;
    my $t = T12->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4}, 'MIXINS AUTOLOAD');
}

{
    my $t = T12->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4}, 'MIXINS AUTOLOA second');
}

