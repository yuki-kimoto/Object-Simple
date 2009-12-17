package M12;
use Object::Simple;

sub m6 : Attr {}

sub initialize {
    my $self = shift;
    $self->m6(6);
}

Object::Simple->build_class;
