package M11;
use Object::Simple;

sub m4 : Attr {}

sub initialize {
    my $self = shift;
    $self->m4(4);
}

Object::Simple->build_class;
