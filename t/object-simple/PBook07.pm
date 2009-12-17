package PBook07;
use base 'Book07';
use Object::Simple;

sub new{
    my ( $self, @args ) = @_;
    # ... You do what you want to do
    
    return $self->SUPER::new( @args );
}

sub author : Attr { }

Object::Simple->build_class;
