package T14;
use Object::Simple::Old(mixins => ['M15_2', 'M15']);

sub m3 {
    my $self = shift;
    return $self->call_super('m3');
}

Object::Simple::Old->build_class;
