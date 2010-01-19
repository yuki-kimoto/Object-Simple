package M12;
use Object::Simple::Old;

sub m6 : Attr {}

sub initialize {
    my $self = shift;
    $self->m6(6);
}

Object::Simple::Old->build_class;
