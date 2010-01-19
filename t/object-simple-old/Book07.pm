package Book07;
use Object::Simple::Old;

sub new{
    my ( $self, @args ) = @_;
    # ... You do what you want to do
    
    return $self->SUPER::new( @args );
}

sub title : Attr { }

Object::Simple::Old->build_class;
