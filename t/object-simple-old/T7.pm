package T7;
use Object::Simple::Old;

sub a1 : Attr { auto_build => \&m1 }

sub m1{
    shift->a1( 1 );
}

sub a2 : Attr { 
    auto_build => sub{
        shift->a2( 2 ) 
    }, 
}

Object::Simple::Old->build_class;
