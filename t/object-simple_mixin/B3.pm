package B3;
use Object::Simple::Old;

sub m1 : Attr {};

sub initialize {
    my $self = shift;
    $self->m1(1);
}



Object::Simple::Old->build_class;

