package M11;
use Object::Simple::Old;

sub m4 : Attr {}

sub initialize {
    my $self = shift;
    $self->m4(4);
}

Object::Simple::Old->build_class;
