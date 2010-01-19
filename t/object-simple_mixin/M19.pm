package M19;
use Object::Simple::Old;

sub m1 { $_[0]->M19($_[1]) }

sub m7 {
    my $self = shift;
    return $_[0] + $_[1];
}

Object::Simple::Old->build_class;
