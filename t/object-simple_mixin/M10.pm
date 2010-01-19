package M10;
use Object::Simple::Old;

sub m3 : Attr {}

sub initialize {
    my ($self, $val) = @_;
    $self->m3($val);
}

Object::Simple::Old->build_class;
