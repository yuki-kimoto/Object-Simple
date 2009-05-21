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

# setter return value
{
    my $book = Book->new;
    my $current_default = $book->author( 'b' );
    ok( !$current_default, 'return old value( default ) in case setter is called' );
    
    my $current = $book->author( 'c' );
    ok( !$current, 'return old value in case setter is called' );
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
    is_deeply( $p, { x => 1, y => 1, p => $Object::Simple::META->{ attr }{ Point }{ p }{ default } }, 'default overwrited' );
    cmp_ok( ref $Object::Simple::META->{ attr }{ Point }{ p }{ default }, 'ne', $p->p, 'default different ref' );
}

use MyTest1;
{
    my $t = MyTest1->new;
    
    eval{ $t->x( 1 ) };
    if( $@ ){
        fail 'type $_ OK';
    }
    else{
        pass 'type $_ OK';
    }
    
    eval{ $t->x( 0 ) };
    if( $@ ){
        pass 'type $_ NG';
    }
    else{
        fail 'type $_ NG';
    }
    
    eval{ $t->q( 1 ) };
    if( $@ ){
        fail 'type return true value';
    }
    else
    {
        pass 'type return true value';
    }
    
    eval{ $t->r( 1 ) };
    like( $@, qr/MyTest1::r Type error/ , 'type return faluse value.' );
    is_deeply( [ $@->type, $@->class, $@->attr ], [ 'type_invalid', 'MyTest1', 'r' ], 'type invalid. Object::Simple::Error object' );
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
    is_deeply( [ $@->type, $@->class, $@->attr ], [ 'read_only', 'T2', 'x' ], 'read only error object' );
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

use T8;
{
    my $t = T8->new;
    
    my $ret1 = $t->a1( 2 );
    is( $ret1, 1, 'setter return value old' );
    
    my $ret2 = $t->a2( 3 );
    is( $ret2, 3, 'setter return value current' );
    
    my $ret3 = $t->a3( 4 );
    isa_ok( $ret3, 'T8', 'setter return value self' );
    
    my $ret5 = $t->a5( 5 );
    ok( !$ret5, 'setter return value default' );

    my $ret6 = $t->a6( 5 );
    ok( !$ret6, 'setter return value default' );
    
}


use T9;
{
    eval{ T9->new };
    is_deeply( [ $@->type, $@->message, $@->class, $@->attr ], [ 'attr_required', "Attr 'm1' is required.", 'T9', 'm1' ], 'new required' );

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

# type constraint
use T11;
{
    my $t = T11->new;
    
    # bool
    eval{ $t->bool( 1 ) };
    ok( !$@, 'bool 1');
    eval{ $t->bool( 0 ) };
    ok( !$@, 'bool 0');
    eval{ $t->bool( undef) };
    ok( !$@, 'bool undef' );
    eval{ $t->bool( '' ) };
    ok( !$@, 'bool null string');
    eval{ $t->bool( 2 ) };
    ok( $@ );
    isa_ok( $@, 'Object::Simple::Error' );
    is_deeply( [ $@->type, $@->message, $@->class, $@->attr, $@->value ],
        [
             'type_invalid',
             "T11::bool Type error",
             "T11",
             "bool",
             2,
        ], 'Object::Simple::Error' );
    
    
    # undef
    eval{ $t->undef( undef ) };
    ok( !$@, 'undef undef' );
    eval{ $t->undef( 1 ) };
    ok( $@, 'undef some value');
    
    # defined
    eval{ $t->defined( 1 ) };
    ok( !$@, 'defined 1');
    eval{ $t->defined( undef ) };
    ok( $@, 'defined undef');
    
    # value
    eval{ $t->value( 1 ) };
    ok( !$@, 'value 1' );
    eval{ $t->value( [] ) };
    ok( $@, 'value []' );
    
    # num
    eval{ $t->num( 1.24 ) };
    ok( !$@, 'num 1.24' );
    eval{ $t->num( 'a' ) };
    ok( $@, 'num a');
    
    # int
    eval{ $t->int( 1.45 ) };
    ok( $@, 'int 1.45' );
    eval{ $t->int( 1234 ) };
    ok( !$@, 'int 1234');
    
    # str
    eval{ $t->str( 'aa1' ) };
    ok( !$@, 'str aa1' );
    eval{ $t->str( [] ) };
    ok( $@, 'str []' );
    
    # class_name
    eval{ $t->class_name( 'Object::Simple::PPP::AAA' ) };
    ok( !$@, 'class_name Object::Simple::PPP::AAA' );
    eval{ $t->class_name( '()' ) };
    ok( $@, 'class_name ()');
    
    # ref
    eval{ $t->ref( [] ) };
    ok(!$@, 'ref []');
    eval{ $t->ref( 'a' ) };
    ok($@, 'ref a');
    
    # scalar_ref
    eval{ $t->scalar_ref( \do{ 1 } ) };
    ok(!$@, 'scalar_ref do{ 1 }');
    eval{ $t->scalar_ref( 1 ) };
    ok( $@, 'scalar ref 1' );
    
    # array ref
    eval{ $t->array_ref( [] ) };
    ok(!$@, 'array_ref []');
    eval{ $t->array_ref( 1 ) };
    ok($@, 'array_ref 1' );
    
    # hash_ref
    eval{ $t->hash_ref( {} ) };
    ok( !$@, 'hash_ref {}' );
    eval{ $t->hash_ref( 123 ) };
    ok( $@, 'hash_ref 123' );
    
    # code_ref
    eval{ $t->code_ref( sub{} ) };
    ok( !$@, 'code_ref sub{} ');
    eval{ $t->code_ref( 1 ) };
    ok( $@, 'code ref 1');
    
    # regex_ref
    eval{ $t->regexp_ref( qr// ) };
    ok( !$@, 'regexp_ref qr//');
    eval{ $t->regexp_ref( 1 ) };
    ok( $@, 'regexp_ref 1');
    
    # glob_ref
    {
        use Symbol;
        my $glob = gensym();
        eval{ $t->glob_ref( $glob ) };
        ok(!$@, 'glob_ref *aaa');
        eval{ $t->glog_ref( 1 ) };
        ok($@, 'glob_ref 1');
    }
    
    # file_handle
    require File::Temp;
    my $fh = File::Temp::tempfile();
    eval{ $t->file_handle( $fh )  };
    ok( !$@, 'file_handle tmpfile');
    eval{ $t->file_handle( 1 ) };
    ok( $@, 'file_handle 1');
    
    # object
    use CGI;
    eval{ $t->object( CGI->new ) };
    ok(!$@, 'object CGI');
    eval{ $t->object( 1 ) };
    ok($@, 'object 1');
    
    # isa
    use IO::File;
    eval{ $t->class( IO::File->new ) };
    ok( !$@, 'class IO::File');
    eval{ $t->class( CGI->new ) };
    ok( $@, 'class CGI' );
    
    eval{ $t->manual( 5 ) };
    ok( !$@, 'manual 5' );
    eval{ $t->manual( 4 ) };
    ok( $@, 'manual 4' );
}

{
    use T12;
    my $t = T12->new( 1, 2 );
    is_deeply( $t, { a => 1, b => 2, c => 3, no_rest => 1 }, '_arrange_args and _init override' );
}


{

    eval{
        Object::Simple::Error->throw( type => 'err_type', message => 'message', info => { a => '1' } );
    };
    
    my $err_obj = Object::Simple->error;
    is( $err_obj->type, 'err_type', 'err_obj type' );
    is( $err_obj->message, 'message', 'err_obj message' );
    like( $err_obj->position, qr/ at /, 'err_obj position' );
    is_deeply( $err_obj->info, { a => 1 }, 'err_obj info' );
    
    my $second_err_obj = Object::Simple->error;
    is( $err_obj->type, $second_err_obj->type, '$@ saved' );
    
    $@ = undef;
    
    ok( !Object::Simple->error, '$@ is undef' );
    
    $@ = "aaa";
    
    my $no_simo_err = Object::Simple->error;
    is_deeply( [ $no_simo_err->type, $no_simo_err->message, $no_simo_err->position, $no_simo_err->info ],
               [ 'unknown', 'aaa', '', {} ], 'no Object::Simple::Error' );
}

__END__


