package T15;
use Object::Simple( base => 'B4', mixins => ['M18', 'M19']);

sub m1 {
    my $self = shift;
    return $self->UPPER_m1;
}

sub m5 : Attr {}

sub new {
    my $self = shift;
    return $self->UPPER_new( m5 => 5);
}

sub m6 {
    my $self = shift;
    $self->UPPER_m6;
}


Object::Simple->build_class;
