package T45_Base_Base;
use Object::Simple::Old;

sub m6 {
    my $self = shift;
    return $_[0] + $_[1];
}

Object::Simple::Old->build_class;
