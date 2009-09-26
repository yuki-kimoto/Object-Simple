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

# mixins  marged attribute
{
    use T11;
    my $t = T11->new;
    is_deeply( $t, {m1 => 1, m2 => 4, m3 => 2, m4 => 2, m5 => 5, m6 =>6}, 'mixins attr');
}

# mixin_methods
{
    use T12;
    my $t = T12->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4}, 'mixin_methods');
}

{
    my $t = T12->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4}, 'mixin_methods');
}

use T13;
{
    my $t = T13->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4, m5 => 5, m6 => 6, m7 => 7}, 'MIXINS AUTOLOA second');
}

# mixin double
use T14;
{
    my $t = T14->new;
    is_deeply($t, {m1 => 1, m2 => 2}, 'mixin double');
}

# UPPER_******
use T15;
{
    my $t = T15->new;
    $t->m1;
    $t->M19;
    is($t->M19, 1, 'UPPER_method mixin class 1');
    
    $t->m2;
    is($t->M18, 1, 'UPPER_method mixin class 2');
    
    $t->m3;
    is($t->B4, 1, 'UPPER_method base class 1');
    
    $t->m4;
    is($t->B5, 1, 'UPPER_method base class 2');
    
    is($t->m5, 5, 'UPPER_method Object::Simple');
    
    eval{ $t->m6 };
    like($@, qr/Cannot locate method 'm6' via base class of T15/, 'UPPER_method no exist');
}

# call_mixin
{
    my $t = T15->new;
    is($t->m7, 3, 'call_mixin');
    
    eval{ $t->m8 };
    like($@, qr/"NoExist::m7 from T15" is not exist/, 'call_mixin error1');

    eval{ $t->m9 };
    like($@, qr/"M19::no_exist from T15" is not exist/, 'call_mixin error2');

    eval{ $t->m10 };
    like($@, qr/":: from T15" is not exist/, 'call_mixin error3');

    eval{ $t->m11 };
    like($@, qr/"M19:: from T15" is not exist/, 'call_mixin error4');
    
}

use T16;
{
    is(T16->m1, 'T16-m1', 'class_attr mixin1');
    is(T16->m2, 'M21-m2', 'class_attr mixin2');
    is(T16->m3, 'M21-m3', 'class_attr miixn3');
}

use T17;
{
    is_deeply(
        $Object::Simple::META->{'T17'}{class_attr_options},
        { m1 => {weak => 1}, m2 => {chained => 0}, m3 => {chained => 0}},
        'meta information class_attr_options'
    );
}

# Mixin Translate and Output accessor
use T18;
{
    my $t = T18->new(m1 => 1);
    is($t->m1, 1, 'mixin translate accessor');
    is($t->m2->m1, 1, 'mixin translate accessor');
    
    $t->m1_to(\my $m1_result);
    is($m1_result, 1, 'mixin output accessor');
}

__END__

