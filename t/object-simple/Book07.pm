package Book07;
use Object::Simple;

sub new{
    my ( $self, @args ) = @_;
    # ... You do what you want to do
    
    return $self->SUPER::new( @args );
}

sub title : Attr { }

Object::Simple->build_class;
