use Test::More  'no_plan';
use strict;
use warnings;

use lib 't/01-core';

BEGIN{ use_ok( 'Object::Simple' ) }
can_ok( 'Object::Simple', qw( new ) ); 

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
    eval{
        my $book = Book->new( 'a' );
    };
    like( 
        $@, qr/key-value pairs must be passed to Book::new/,
        'not pass key value pair'
    );
}

{
    my $book = Book->new( noexist => 1 );
    ok( !$book->{ noexist }, 'no exist attr set value' );
}

{
    my $book = Book->new( title => undef );
    ok( exists $book->{ title } && !defined $book->{ title } , 'new undef pass' );
}

# setter return value
{
    my $book = Book->new;
    my $current_default = $book->author( 'p' );
    is( $current_default, 'p', 'return current value( default ) in case setter is called' );
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
    is_deeply($p, {x => 1, y => 1, p => $Object::Simple::META->{attr_options}{Point}{p}{default}->()}, 'default overwrited' );
    cmp_ok(ref $Object::Simple::META->{attr_options}{Point}{p}{default}, 'ne', $p->p, 'default different ref' );
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
    
    ok( Scalar::Util::isweak( $t->{ m1 } ), 'weak ref' );
    ok( !Scalar::Util::isweak( $t->{ m2 } ), 'not weak ref' );
    
    $o = undef;
    ok( !$t->m1, 'ref is removed' );
    1;
}

{
    use T13;
    my $t = T13->new;
    is_deeply($t, {title => 1, author => 3}, 'override');
    
}

eval "use T15";
like($@, qr/'A' is bad. attribute must be 'Attr'/, 'bat attribute name');

{
    use T16;
    my $t = T16->new;
    my $r = $t->m1('1');
    is($t->m1, '1', 'set');
    is($t, $r, 'chained');
}
__END__


