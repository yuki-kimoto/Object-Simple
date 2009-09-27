package T45_Base;
use Object::Simple(base => 'T45_Base_Base');

sub m1 {
    my $self = shift;
    my $val = shift;
    return $val + 1;
}

sub m4 {
    my $self = shift;
    my $val = shift;
    return $val + 4;
}

sub m5 {
    my $self = shift;
    my $val = shift;
    return $val + 5;
}

sub m6 {
    my $self = shift;
    $self->Object::Simple::call_super('m6', @_) * 3;
}


Object::Simple->build_class;
