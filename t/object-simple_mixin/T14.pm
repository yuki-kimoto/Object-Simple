package T14;
use Object::Simple(mixins => ['M15_2', 'M15']);

sub m3 {
    my $self = shift;
    return $self->call_super('m3');
}

Object::Simple->build_class;
