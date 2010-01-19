package T45_Mixin;
use Object::Simple::Old;

sub m1 {
    my $self = shift;
    return $self->SUPER::m1(3);
}

sub m2 {
    my $self = shift;
    return $self->SUPER::m1(4);
}

sub m3 {
    my $self = shift;
    return $self->m1;
}

sub m4 {
    my $self = shift;
    return $self->SUPER::m1(0) + $self->SUPER::m4(0);
}

sub m5 {
    my $self = shift;
    return $self->SUPER::m5(0) + $self->SUPER::m1(0);
}

sub m6 {
    my $self = shift;
    return $self->SUPER::m6(@_) * 4;
}


Object::Simple::Old->build_class;
