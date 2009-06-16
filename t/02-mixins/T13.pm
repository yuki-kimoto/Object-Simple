package T13;
use Object::Simple(base => 'T12', mixins => ['M12', 'M13', 'M14']);

sub m5 : Attr {}

sub new {
    my $self = shift->Object::Simple::new(@_);
    $self->initialize;
    return $self;
}

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    $self->MIXINS_initialize;
    $self->m5(5);
}

Object::Simple->build_class;
