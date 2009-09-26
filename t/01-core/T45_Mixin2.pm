package T45_Mixin2;
use Object::Simple;

sub m6 {
    my $self = shift;
    return $self->SUPER::m6(0) + 2;
}


Object::Simple->build_class;
