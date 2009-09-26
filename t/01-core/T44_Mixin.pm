package T44_Mixin;
use strict;
use warnings;

sub m1 {
    my $self = shift;
    return $self->SUPER::m1(2);
}

sub m6 {
    my $self = shift;
    return $self->SUPER::m6(0) + 1;
}

1;