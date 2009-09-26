package T45_Base;
use Object::Simple;

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


Object::Simple->build_class;
