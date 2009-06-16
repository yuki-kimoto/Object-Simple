package T12;
use Object::Simple(base => 'B3', mixins => ['M10', 'M11']);

sub m2 : Attr {}

sub new {
    my $self = shift->Object::Simple::new(@_);
    $self->initialize;
    return $self;
}

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    $self->MIXINS_initialize(3);
    $self->m2(2);
}



Object::Simple->build_class;
