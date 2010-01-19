package T45_Mixin2;
use Object::Simple::Old;

sub m6 {
    my $self = shift;
    $self->SUPER::m6(@_) + 3
}



Object::Simple::Old->build_class;
