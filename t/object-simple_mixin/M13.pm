package M13;
use Object::Simple::Old;

sub m7 : Attr {}

sub initialize {
    my $self = shift;
    $self->m7(7);
}

Object::Simple::Old->build_class;
