use Test::More tests => 3;

BEGIN{ use_ok( 'Simo' ) }
can_ok( 'Simo', qw( ac new ) ); 


package Book;
use Simo;

sub new{
    my ( $self, @args ) = @_;
    # ... You do what you want to do
    
    return $self->SUPER::new( @args );
}

sub title{ ac }

package PBook;
use base 'Book';
use Simo;

sub new{
    my ( $self, @args ) = @_;
    # ... You do what you want to do
    
    return $self->SUPER::new( @args );
}

sub author{ ac }

package main;
my $pbook = PBook->new( title => 'a', author => 'b' );

is_deeply( $pbook, { title => 'a', author => 'b' }, 'super class' );


