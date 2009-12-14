use Test::More 'no_plan';
use strict;
use warnings;
 
use lib 't/01-core';

BEGIN{ use_ok( 'Object::Simple' ) }
can_ok( 'Object::Simple', qw( new ) ); 

# Test name
my $test;
sub test{$test = shift}

my $o;


use Book;
# new method
{
    my $book = Book->new;
    isa_ok( $book, 'Book', 'It is object' );
    isa_ok( $book, 'Object::Simple', 'Inherit Object::Simple' );
}
 
{
    my $book = Book->new( title => 'a' );
    
    is_deeply( 
        [ $book->title ], [ 'a' ],
        'setter and getter and constructor' 
    );
}
 
{
    my $book = Book->new( { title => 'a', author => 'b' } );
    
    is_deeply( 
        [ $book->title, $book->author ], [ 'a', 'b' ],
        'setter and getter and constructor' 
    );
}
 
{
    my $book = Book->new( 'a' );
    ok(exists $book->{a}, 'odd number new');
    ok(!defined $book->{a},'odd number new');
}
 
{
    my $book = Book->new( noexist => 1 );
    is($book->{ noexist }, 1, 'no exist attr set value' );
}
 
{
    my $book = Book->new( title => undef );
    ok( exists $book->{ title } && !defined $book->{ title } , 'new undef pass' );
}

{
    eval{Book->title(3)};
    ok($@, 'set from class');
}
 
{
    my $t = Book->new( price => 6 );
    my $c = $t->new;
    is($c->price, 1, 'call new from object');
    
}
 
# reference
{
    my $book = Book->new;
    my $ary = [ 1 ];
    $book->title( $ary );
    my $ary_get = $book->title;
    
    is( $ary, $ary_get, 'equel reference' );
    
    push @{ $ary }, 2;
    is_deeply( $ary_get, [ 1, 2 ], 'equal reference value' );
    
    # shallow copy
    my @ary_shallow = @{ $book->title };
    push @ary_shallow, 3;
    is_deeply( [@ary_shallow],[1, 2, 3 ], 'shallow copy' );
    is_deeply( $ary_get, [1,2 ], 'shallow copy not effective' );
    
    push @{ $book->title }, 3;
    is_deeply( $ary_get, [ 1, 2, 3 ], 'push array' );
}
 
use Point;
# direct hash access
{
    my $p = Point->new;
    $p->{ x } = 2;
    is( $p->x, 2, 'default overwrited' );
    
    $p->x( 3 );
    is( $p->{ x }, 3, 'direct access' );
    
    is( $p->y, 1, 'defalut normal' );
}
{
    my $p = Point->new;
    is_deeply($p, {x => 1, y => 1, p => $Object::Simple::CLASS_INFOS->{Point}{accessors}{p}{options}{default}->()}, 'default overwrited' );
    cmp_ok(ref $Object::Simple::CLASS_INFOS->{Point}{accessors}{p}{options}{default}, 'ne', $p->p, 'default different ref' );
}
 
use T1;
{
    my $t = T1->new( a => 1 );
    $t->a( undef );
    ok( !defined $t->a, 'undef value set' );
}
 
# read_only test
use T2;
{
    my $t = T2->new;
    is( $t->x, 1, 'read_only' );
    
    eval{ $t->x( 3 ) };
    like( $@, qr/T2::x is read only/, 'read_only die' );
}
 
use T3;
{
    my $t1 = T3->new;
    my $t2 = T3->new;
    isnt( $t1->x, $t2->x, 'default adress is diffrence' );
    is_deeply( $t1->x, $t2->x, 'default value is same' );
    
}

use T3_2;
{
    my $t = T3_2->new(m1 => undef, m2 => undef);
    ok(!$t->m1, 'default new set undef');
    ok(!$t->m2, 'default code ref new set undef');
}
 
use T4;
{
    my $o = T4->new;
    is( $o->a1, 1, 'auto_build' );
    is( $o->a2, 1, 'auto_build direct access' );
    is( $o->_a4, 4, 'auto_build start under bar' );
    is( $o->__a5, 5, 'auto_build start double under bar' );
    
}
 
{
    my $o = T4->new;
    $o->a1(undef);
    ok(exists $o->{a1}, 'auto_build set undef key');
    ok(!defined $o->{a1}, 'auto_build set undef value');
    
    my $v = $o->a1;
    ok(exists $o->{a1}, 'auto_build set undef key');
    ok(!defined $o->{a1}, 'auto_build set undef value');
}
 
 
use T6;
 
{
    my $o = T6->new;
    is( $o->build_m1, 1, 'first build accessor' );
}
 
use T7;
 
{
    my $o = T7->new;
    is( $o->a1, 1, 'auto_build pass method ref' );
    is( $o->a2, 2, 'auto_build pass anonimous sub' );
}
 
use T10;
{
    my $t = T10->new;
    
    my $o = { a => 1 };
    $t->m1( $o );
    
    require Scalar::Util;
    
    ok( Scalar::Util::isweak($t->{m1}), 'weak ref' );
    #ok( Scalar::Util::isweak($t->m1), 'weak ref' );
 
    ok( !Scalar::Util::isweak( $t->{ m2 } ), 'not weak ref' );
    
    is_deeply($t->m1, {a => 1}, 'weak get');
    
    $o = undef;
    ok( !$t->m1, 'ref is removed' );
    
}
 
{
    use T13;
    my $t = T13->new;
    is_deeply($t, {title => 1, author => 3}, 'override');
}
 
eval "use T15";
like($@, qr/Accessor type 'A' is not exist. Accessor type must be 'Attr', 'ClassAttr', 'ClassObjectAttr'/, 'Not exist accessor name');
 
{
    use T16;
    my $t = T16->new;
    my $r = $t->m1('1');
    is($t->m1, '1', 'set');
    is($t, $r, 'chained');
    
    my $d = [3];
    $t->m2($d);
    is_deeply($t->m2, [3], 'weak and chained get value');
    
    my $d2 = [5];
    my $r2 = $t->m2($d2);
    is($r2, $t, 'weak and chained set value ret');
    is_deeply($t->m2, $d2, 'weak and chained set value');
    
    is($t->m3(1), $t, 'defaut is chained');
    
    is($t->m4(1), 1, 'chained => 0');
}
 
{
    my $t = Book->new;
    is($t->price, 1, 'default value not setting' );
}
{
    my $t = Book->new(price => 100);
    is($t->price, 100, 'default value setting');
}
{
    my $t = Book->new(title => 1);
    is($t->title, 1, 'no default value');
}
 
{
    my $t = T3->new;
    is_deeply($t->x, [1], 'new default value reference');
}
 
{
    my $d = [1];
    my $t = T10->new(m1 => $d);
    is_deeply($t->m1, [1], 'new weak data');
    ok(Scalar::Util::isweak($t->{m1}), 'new weak');
}
 
{
    eval"use T17";
    like($@, qr/Value of 'default' option must be a code reference or constant value\(T17::m1\)/, 'defalt error');
}
 
{
    eval "use T18";
    like($@, qr/T18::m1 'aaa' is invalid accessor option/);
}
 
{
    use T19;
    ok($T19::OK, 'unimport MODIFY_CODE_ATTRIBUTES');
}

{
    use T19::AAA;
    my $t = T19::AAA->new;
    is_deeply($t, {m1 => 1}, 'class name contain ::');
}

{
    my $t = T19::AAA->new;
    is($t->m2, 2, 'auto build class name contain ::');
}

{
    use T20;
    my $t = T20->new;
    $t->m1(0);
    is_deeply($t->m1, [0], 'type array set a value');
    
    $t->m1(1,2);
    is_deeply($t->m1, [1, 2], 'type array set two valus');
    
    $t->m1([2,3]);
    is_deeply($t->m1, [2, 3], 'type attry set array ref');
    
    $t->m1(undef);
    ok(!defined $t->m1, 'type attry set undef');
    
    
    
    $t->m2(k1 => 1, k2 => 1);
    is_deeply($t->m2, {k1 => 1, k2 => 1}, 'type hash set four valus');
    
    $t->m2({k => 1});
    is_deeply($t->m2, {k => 1}, 'type hash set hash ref');

    $t->m2(undef);
    ok(!defined $t->m2, 'type hash set undef');
    
}

{
    eval "use T21";
    like($@, qr/'type' option must be 'array' or 'hash' \(T21::m1\)/, 'type is invalid');
}

{
    use T22;
    
    my $t = T22->new;
    $t->m1({ m1 => 1});
    isa_ok($t->m1, 'T23');
    is($t->m1->m1, 1, 'convert');
    
    $t->m1(T23->new(m1 => 2));
    isa_ok($t->m1, 'T23');
    is($t->m1->m1, 2, 'no convert');
    
    $t->m1(undef);
    ok(!$t->m1, 'no convert undef');
    
    $t->m2(2);
    is($t->m2, 4, 'convert sub');
}

{
    my $t = T22->new(m1 => { m1 => 1 });
    isa_ok($t->m1, 'T23');
    is($t->m1->m1, 1, 'convert');
}
    
{
    my $t = T22->new(m1 => T23->new(m1 => 2));
    isa_ok($t->m1, 'T23');
    is($t->m1->m1, 2, 'no convert');
}

{
    my $t = T22->new;
    ok(!defined $t->m1, 'constructor no convert');
}

{
    my $t = T22->new(m1 => undef);
    ok(!defined $t->m1, 'constructor no convert undef');
}

{
    my $t = T22->new;
    $t->m2(2);
    is($t->m2, 4, 'convert sub');

}

{
    my $t = T22->new(m2 => 2);
    is($t->m2, 4, 'convert sub from constructor');
}

{
    my $t = T22->new;
    ok(!defined $t->m2, 'convert sub constructor no convert');
}

{
    my $t = T22->new(m2 => undef);
    is($t->m2, 0, 'convert undef from constructor');
}

{
    use T24;
    my $t = T24->new( m1 => [1,2], m2 => { k => 1 }, m3 => [2,3] );
    my $array = $t->m1;
    my @array = $t->m1;
    
    is_deeply($array, [1, 2], 'deref array 1');
    is_deeply([@array], [1, 2], 'deref array 2');
    
    my $hash = $t->m2;
    my %hash = $t->m2;
    
    is_deeply($hash, {k => 1}, 'deref hash 1');
    is_deeply({%hash}, {k => 1}, 'deref hash 2');
}

{
    eval"use T25";
    like($@, qr/\Q'deref' option must be specified with 'type' option (T25::m1)/, 'type is invalid');
}

# Trigger

use T27;
{

    my $t = T27->new;
    is($t->m2, 10, 'trigger default value');
    $t->m1(1);
    is($t->m2, 2, 'trigger set value');
}

{
    my $t = T27->new(m1 => 1);
    is($t->m2, 2, 'trigger set value from constructor');
}

{
    my $t = T27->new;
    $t->m3(undef);
    is($t->m4, 1, 'trigger shen set undef');
}

{
    my $o = T23->new;
    my $t = T27->new(m5 => $o);
    is($t->m6, 1, 'weaken on trigger from constructor');
}

{
    my $o = T23->new;
    my $t = T27->new;
    $t->m5($o);
    is($t->m6, 1, 'weaken on trigger from constructor');
}

{
    my $t = T27->new(m3 => undef);
    is($t->m4, 1, 'trigger when set undef from constructor');
}

{
    my $t = T27->new;
    $t->m7(1);
    $t->m7(2);
    is($t->m7_check, 3, 'trigger old value');
}

{
    eval "use T28";
    like($@, qr/\Q'trigger' option must be code reference (T28::m1)/, 'trigger is not code ref');
    
}

# Variouse test
use T29;
{
    my $t = T29->new;
    is_deeply($t->m1, { m1 => 1}, 'default');
    
    delete $t->{'m1'};
    $t->m1; # auto_build;
    is($t->m2, 3, 'various test ok');
    
    my $self = $t->m1(m1 => 1);
    is($t, $self, 'chained');
    
}

use T30;
{
    my $t = T30->new;
    $t->m1(1);
    
    is($t->m2->m1, 1, 'translate set value');
    is($t->m1, 1, 'translate get value');
}

{
    my $t = T30->new(m1 => 1);
    ok(!exists $t->{m1}, 'transate delete key');
    is($t->m2->m1, 1, 'translate set value from constructor');
}


{
    my $t = T30->new;
    $t->m3(1);
    is($t->m4->m2->m1, 1, 'translate set value multipule');
    is($t->m3, 1, 'translate get value multipule');
}

{
    my $t = T30->new;
    my $r = $t->m5(1);
    is($r, $t, 'translate setter return chained');
}

{
    my $t = T30->new;
    my $r = $t->m6(1);
    is($r, $t, 'translate setter return chained though not chained');
}

{
    my $t = T30->new;
    $t->m7(1, 2);
    my $r = $t->m7;
    is_deeply($r, [1, 2], 'translate getter return scalar context value array');
    
    my @r = $t->m7;
    is_deeply([@r], [1, 2], 'translate getter return list context value array');
}

{
    # extend parent
    my $t = T30->new;
    $t->m9(1);
    
    is($t->m2->m1, 1, 'translate set value');
    is($t->m9, 1, 'translate get value');
}

{
    # extend parent constructor 
    my $t = T30->new(m9 => 1);
    
    is($t->m2->m1, 1, 'translate set value');
    is($t->m9, 1, 'translate get value');
}

{
    my $t = T30->new;
    $t->m8(k => 1);
    my $r = $t->m8;
    is_deeply($r, {k => 1}, 'translate getter return scalar context value hash');
    
    my %r = $t->m8;
    is_deeply({%r}, {k => 1}, 'translate getter return list context value hash');
}

{
    eval "use T32;";
    like($@, qr/\QT32::m1 '2->m1' is invalid. Translate 'target' option must be like 'method1->method2'/, 'invalid translate value');

    eval "use T32_2;";
    like($@, qr/\QT32_2::m1 '' is invalid. Translate 'target' option must be like 'method1->method2'/, 'invalid translate value');

    eval "use T33;";
    ok($@, 'translate invalid 2');
    eval "use T34;";
    ok($@, 'translate invalid 3');
    eval "use T35;";
    ok($@, 'translate invalid 4');
}

{
    eval "use T36;";
    like($@, qr/T36::m1 'default' is invalid accessor option/);
    
}

{
    use T37;
    T37->m1(1);
    is(T37->m1, 1, 'class accessor get');
    T37->m1(1)->m1(2);
    is(T37->m1, 2, 'class accessor chained');
    
    is(T37->m2(2), 2, 'class accessor no chain');
    
    my $p = {};
    T37->m3($p);
    ok(Scalar::Util::isweak(T37->class_attrs->{m3}), 'class accessor weak class attr');
    is(T37->m3, $p, 'class accessor weak get');
    
    my $o = T37->new;
    ok(Scalar::Util::isweak($o->class_attrs->{m3}), 'class accessor weak class attr');
    ok($o->exists_class_attr('m3'), 'class accessor exists from object');
    ok($o->class_attrs->{m3}, 'class accessor exists from object');
    
    is_deeply($o->delete_class_attr('m3'), {}, 'class accessor delete from object');
    ok(!defined $o->class_attrs->{m3}, 'class accessor delete from object');
    
    T37->m3($p);
    is_deeply($o->delete_class_attr('m3'), {}, 'class accessor delete from object');
    ok(!defined $o->class_attrs->{m3}, 'class accessor delete from object');
    
    eval{T37->m4(4)};
    like( $@, qr/T37::m4 is read only/, 'read_only die' );
    
    is(T37->m5, 5, 'class accessor auto_build get');
    
    T37->m6(1,2);
    is_deeply([T37->m6], [1, 2], 'class accessor type array and deref get');
    
    T37->m7({k => 1});
    is_deeply({T37->m7}, {k => 1}, 'class accessor type hash and deref get');
    
    T37->m8(8);
    is(T37->m9, 16, 'class accessor get');
}   

{
    my $o = T37->new;
    eval{ $o->m1 };
    like($@, qr/T37::m1 must be called from class, not instance/, 'class accessor called from object');
}

{
    use T38;
    T37->m1(1);
    is(T37->m1, 1, 'inherit class accessor');
    
    T38->m1(2);
    is(T38->m1, 2, 'inherit class accessor');
    is(T37->m1, 1, 'inherit class accessor');
    
    T37->m1(3);
    is(T38->m1, 2, 'inherit class accessor');
}

{
    is_deeply({T37->m10}, {}, 'inherit super class accessor');
    
    is_deeply({T38->m10}, { k1 => 1 }, 'inherit super class accessor');
    
    use T39;
    is_deeply({T39->m10}, { k1 => 1, k2 => 2 }, 'inherit super class accessor');
}

### Output accessor
{
    use T40;
    T40
      ->new
      ->m1_to(\my $m1_result)
      ->m2_to(\my $m2_result)
    ;
    
    is($m1_result, 1, 'Output scalar');
    is_deeply($m2_result, [1, 2], 'Output array ref');
}

### resist_attribute_info
{
    use T41;
    T41
      ->new
      ->m1_to(\my $m1_result);
    
    is($m1_result, 1, 'resist_attribute_info');
}

### extend base class attribute option
{
    use T42;
    my $m_base = T42_Base_1->new;
    is_deeply({$m_base->m1}, {a => 1}, 'base class attr option');
    
    my $m = T42->new;
    is_deeply({$m->m1}, {b => 2}, 'extend options');
    is_deeply({$m->m2}, {c => 1}, 'extend two up options');
    
}

### extend base class attribute option
{
    use T43;
    my $m_base = T43_Base_1->new;
    is_deeply({$m_base->m1}, {a => 1}, 'base class attr option');
    
    my $m = T43->new;
    is_deeply({$m->m1}, {b => 2}, 'extend options');
    is_deeply({$m->m2}, {c => 1}, 'extend two up options');
    is($m->m3, 5, 'extend is ignore');
}

### build_class invalid key
{
    eval{Object::Simple->build_class({no => 1})};
    like($@, qr/'no' is invalid build_class option/, 'build_class invalid key');
}

## Mixin call super class
use T44;
{
    my $o = T44->new;
    is($o->m1, 3, 'Mixin call super class1');
}

use T45;
{
    my $o = T45->new;
    is($o->m1, 4, 'Mixin call super class2');
    is($o->m2, 5, 'Mixin call super class3');
    is($o->m3, 4, 'Mixin call super class4');
    is($o->m4, 5, 'Mixin call super class5');
    is($o->m5, 6, 'Mixin call super class6');
    is($o->m6(6,7), 159, 'Mixin call super class7');
}

use T46;
# ClassObjectAttr
{
    my $o = T46->new;
    $o->m1([1,2]);
    is_deeply(scalar $o->m1, [1, 2], 'ClassObjectAttr object accessor');
    is_deeply([$o->m1], [1, 2], 'ClassObjectAttr object accessor list context');
    ok(!exists $o->{m2});
    is_deeply($o->m2, [5, 6], 'ClassObjectAttr object accessor auto_build');
    
    T46->m1([3, 4]);
    is_deeply(scalar T46->m1, [3, 4], 'ClassObjectAttr class accessor');
    is_deeply([T46->m1], [3, 4], 'ClassObjectAttr class accessor list context');
    ok(!T46->exists_class_attr('m2'));
    is_deeply(T46->m2, [5, 6], 'ClassObjectAttr class accessor auto_build');
    T46->m2;
    
    ok(T46->exists_class_attr('m2'), 'key is exists');
    my $delete = T46->delete_class_attr('m2');
    is_deeply($delete, [5, 6], 'delete value');
    ok(!T46->exists_class_attr('m2'));
}

{
    my $o = T46->new(m1 => 5, m2 => 6);
    is_deeply($o, {m1 => 5, m2 => 6}, 'ClassObjectAttr constructor');
}

use T47;
{
    my $p = T47->m1;
    is(T47->m1, 1, 'initialize_class_object_attr scalar class');
    is_deeply(T47->m2, [1, 2], 'initialize_class_object_attr array class');
    is_deeply(T47->m3, {a => 1, b => 2}, 'initialize_class_object_attr hash class');
}

{
    my $o = T47->new;
    is($o->m1, 1, 'initialize_class_object_attr scalar object');
    is_deeply($o->m2, [1, 2], 'initialize_class_object_attr array object');
    is_deeply($o->m3, {a => 1, b => 2}, 'initialize_class_object_attr hash object');
}

{
    my $p = T47_2->m1;
    is(T47_2->m1, 1, 'initialize_class_object_attr scalar sub class ');
    is_deeply(T47_2->m2, [1, 2], 'initialize_class_object_attr array sub class');
    is_deeply(T47_2->m3, {a => 1, b => 2}, 'initialize_class_object_attr hash sub class');
}

{
    my $o = T47_2->new;
    is($o->m1, 1, 'initialize_class_object_attr scalar sub object');
    is_deeply($o->m2, [1, 2], 'initialize_class_object_attr array sub object');
    is_deeply($o->m3, {a => 1, b => 2}, 'initialize_class_object_attr hash sub object');
}

{
    T47_2->m1(2);
    is(T47->m1, 1, 'no effect');
    is(T47_2->m1, 2, 'no effect');
    my $o = T47_2->new;
    $o->m1;
    is($o->m1, 2, 'copied class');
}

{
    my $o = T47_4->new;
    is($o->m1, 2, 'initialize_class_object_attr scalar multi inherit object');
    is_deeply($o->m2, [1, 2], 'initialize_class_object_attr array multi inherit object');
    is_deeply($o->m3, {a => 1, b => 2}, 'initialize_class_object_attr hash multi inherit object');
}

{
    is(T47->new->m4, 6, 'user clone method');
    is(T47->m6, 3);
    T47->m8;
    ok(!T47->m8, 'default is undef');
}

{
    eval "use T47_Error1";
    like($@, qr/\Q'initialize'-'clone' opiton must be 'scalar', 'array', 'hash', or code reference (T47_Error1::m5)/, 'noexis clone option');
    
    eval "use T47_Error2";
    like($@, qr/\Q'initialize'-'default' option must be scalar, or code ref (T47_Error2::m7)/, 'no dfault option');
    
    eval "use T47_Error3";
    like($@, qr/\Q'initialize' option must be 'clone', or 'default' (T47_Error3::m1)/, 'no dfault option');
    
    eval "use T47_Error4";
    like($@, qr/\Q'initialize' option must be hash reference (T47_Error4::m1)/, 'no dfault option');
    
}

test 'deref';
$o = T47->new;
is_deeply({$o->m9}, {a => 1, b => 2}, "$test : hash");
is_deeply([$o->m10], [1, 2], "$test : array");


test 'ClassObjectAttr initiailize';
isnt(scalar T47->m2, scalar T47_2->m2, "$test : array not copy reforecne");
isnt(scalar T47->m3, scalar T47_2->m3, "$test : hash not copy reforecne");


test 'Super new';
use PBook07;
my $pbook = PBook07->new( title => 'a', author => 'b' );
is_deeply( $pbook, { title => 'a', author => 'b' }, "$test : super new");


test 'Auto strict';
package Book813;
use Object::Simple;
eval'$no_exist = 3;';
package main;
ok($@, $test);


test 'Parant-Child';
package Parent820;
use Object::Simple;
sub children : Attr {}
Object::Simple->build_class;
package Child820;
use Object::Simple;
sub parent : Attr {}
Object::Simple->build_class;
package main;
$o = Parent820->new(children => 1);
is($o->children, 1, 'Parent is ok');
$o = Child820->new(parent => 1);
is($o->parent, 1, 'Child is ok');


test 'builder accessor option';
use T48;
$o = T48->new;
is($o->m1, 1, "$test : attr scalar");
is($o->m2, 14, "$test : attr code ref");
is(T48->m3, 3, "$test : class attr scalar");
is(T48->m4, 28, "$test : class attr code ref");
is($o->m5, 5, "$test : class object attr scalar : object");
is(T48->m5, 5, "$test : class object attr scalar : class");
is($o->m6, 42, "$test : class object attr code ref : object");
is(T48->m6, 42, "$test : class object attr code ref : class");


test 'build accessor option error';
eval "use T48_Error1";
like($@, qr/\Q'build' option must be scalar or code ref (T48_Error1::m1)/,
     "$test");

__END__
