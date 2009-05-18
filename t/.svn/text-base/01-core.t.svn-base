use Test::More  'no_plan';

BEGIN{ use_ok( 'Simo' ) }
can_ok( 'Simo', qw( ac new ) ); 

package Book;
use Simo;

sub title{ ac }
sub author{ ac 'a' }

sub price{ ac
    default => 1,
    set_hook => sub{
        my( $self, $val ) = @_;
        return [ $val + 1, $self ];
    },
}

sub size{ ac
    get_hook => sub{
        my ( $self, $val ) = @_;
        return [ $val, $self ];
    }
}

sub color{ ac
    set_hook => 1,
    get_hook => 1
}

sub description{ ac
    hash_force => 1
}

sub raiting{ ac
    noexist => 1,
}

package main;

# new method
{
    my $book = Book->new;
    isa_ok( $book, 'Book', 'It is object' );
    isa_ok( $book, 'Simo', 'Inherit Simo' );
}

{
    my $book = Book->new( title => 'a', author => 'b' );
    
    is_deeply( 
        [ $book->title, $book->author ], [ 'a', 'b' ],
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
        $@, qr/key-value pairs must be passed to new method/,
        'not pass key value pair'
    );
}

{
    eval{
        my $book = Book->new( noexist => 1 );
    };
    like( $@, qr/Invalid key 'noexist' is passed to Book::new/, 'invalid key to new method' );
}

# set and get array and hash
{
    my $book = Book->new;
    $book->title( 1, 2 );
    
    my $ary_ref = $book->title;
    is_deeply( $ary_ref, [ 1, 2 ], 'set array and get array ref' );
    
    my @ary = $book->title;
    is_deeply( $ary[0], [ 1, 2 ], 'set array and get arrya' );
    
    $book->title( { k => 1} );
    my $hash_ref = $book->title;
    is_deeply( $hash_ref, { k => 1}, 'set hash ref and get hash ref' );
    
    my %hash =%{ $book->title };
    is_deeply( { %hash }, { k => 1 }, 'set hash ref and get hash' );
}

# setter return value
{
    my $book = Book->new;
    my $old_default = $book->author( 'b' );
    is( $old_default, 'a', 'return old value( default ) in case setter is called' );
    
    my $old = $book->author( 'c' );
    is( $old, 'b', 'return old value in case setter is called' );
}

# accessor option
{
    my $book = Book->new;
    my $val_default = $book->price;
    is( $val_default, 1, 'ac default option and set_hook' );
    
    $book->price( 2 );
    my ( $val_set_hook, $self_set_hook ) = @{ $book->price };
    is( $val_set_hook, 3, 'ac set_hook option( val )' );
    is( ref $self_set_hook, 'Book', 'ac set_hook option( arg )' );
    
    eval{
        $book->color( 1 );
    };
    
    ok( $@, 'invalid set_hook' );
    
    
    $book->size( 2 );
    my ( $val_get_hook, $self_get_hook ) = @{ $book->size };
    is( $val_get_hook, 2, 'ac get_hook option( val )' );
    is( ref $self_get_hook, 'Book', 'ac get_hook option( arg )' );
    
    eval{
        $book->color;
    };
    
    ok( $@, 'invalid get_hook' );

    
    $book->description( key => 1 );
    my $description = $book->description;
    is_deeply( $description, { key => 1 }, "ac hash_force option" );
    
    eval{
        $book->raiting;
    };
    like( $@,
        qr/noexist of Book::raiting is invalid accessor option/,
        'no exist accessor option',
    );
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

package Point;
use Simo;

sub x{ ac default => 1 }
sub y{ ac default => 1 }

package main;
# direct hash access
{
    my $p = Point->new;
    $p->{ x } = 2;
    is( $p->x, 2, 'default overwrited' );
    
    $p->x( 3 );
    is( $p->{ x }, 3, 'direct access' );
    
    is( $p->y, 1, 'defalut normal' );
}

# cnstrain
package MyTest1;
use Simo;

sub x{ ac constrain => sub{ $_ == 1 or die 'constrain $_' } }
sub y{ ac constrain => sub{ $_[0] == 1 or die 'constrain $_[0]' } }
sub z{ ac
    constrain => [
        sub{ $_ < 3  or die "" },
        sub{ $_ > 1  or die "" }
    ]
}

sub p{ ac constrain => 'a' }

sub q{ ac constrain => sub{ 1 } };
sub r{ ac constrain => sub{ 0 } };

package main;
{
    my $t = MyTest1->new;
    
    eval{ $t->x( 1 ) };
    if( $@ ){
        fail 'constrain $_ OK';
    }
    else{
        pass 'constrain $_ OK';
    }
    
    eval{ $t->x( 0 ) };
    if( $@ ){
        pass 'constrain $_ NG';
    }
    else{
        fail 'constrain $_ NG';
    }
    
    eval{ $t->y( 1 ) };
    if( $@ ){
        fail 'constrain $_[0] OK';
    }
    else{
        pass 'constrain $_[0]';
    }
    
    eval{ $t->y( 0 ) };
    if( $@ ){
        pass 'constrain $_[0] NG';
    }
    else{
        fail 'constrain $_[0] NG';
    }
    
    eval{ $t->z( 1 ) };
    if( $@ ){
        pass 'constrain multi NG';
    }
    else{
        fail 'constrain multi NG';
    }        
    
    
    eval{ $t->z( 2 ) };
    if( $@ ){
        fail 'constrain multi NG';
    }
    else{
        pass 'constrain multi NG';
    }
    
    eval{ $t->p(1) };
    like( $@, qr/constrain of MyTest1::p must be code ref/,
          'constrain non sub ref' );
    
    eval{ $t->q( 1 ) };
    if( $@ ){
        fail 'constrain return true value';
    }
    else
    {
        pass 'constrain return true value';
    }
    
    eval{ $t->r( 1 ) };
    like( $@, qr/Illegal value 1 is passed to MyTest1::r/ , 'constrain return faluse value' );
}


# filter
package MyTest2;
use Simo;

sub x{ ac filter => sub{ $_ * 2  } }
sub y{ ac filter => sub{ $_[0] * 2 } }
sub z{ ac
    filter => [
        sub{ $_ * 2 },
        sub{ $_ * 2 }
    ]
}

sub p{ ac filter => 'a' }

package main;
{
    my $t = MyTest2->new;
    
    eval{ $t->x( 1 ) };
    is( $t->x, 2, 'filter $_ OK' );

    eval{ $t->y( 1 ) };
    is( $t->y, 2, 'filter $_[0] OK' );
    
    eval{ $t->z( 1 ) };
    is( $t->z, 4, 'filter multi NG' );
    
    eval{ $t->p(1) };
    like( $@, qr/filter of MyTest2::p must be code ref/,
          'filter non sub ref' );
}



# trigger
package MyTest3;
use Simo;

sub w{ ac }
sub x{ ac trigger => sub{ $_->w( $_->x )  } }
sub y{ ac trigger => sub{ $_[0]->w( $_[0]->y ) } }
sub z{ ac
    trigger => [
        sub{ $_->w( $_->z ); },
        sub{ $_->w( $_->w * 2 ) }
    ]
}

sub p{ ac trigger => 'a' }

package main;
{
    my $t = MyTest3->new;
    
    eval{ $t->x( 1 ) };
    is( $t->w, 1, 'trigger $_ OK' );

    eval{ $t->y( 2 ) };
    is( $t->w, 2, 'trigger $_[0] OK' );
    
    eval{ $t->z( 3 ) };
    is( $t->w, 6 , 'trigger multi NG' );

    eval{ $t->p(1) };
    like( $@, qr/trigger of MyTest3::p must be code ref/,
          'trigger non sub ref' );
}

# undef value set
package T1;
use Simo;

sub a{ ac }

package main;
{
    my $t = T1->new( a => 1 );
    $t->a( undef );
    ok( !defined $t->a, 'undef value set' );
}

