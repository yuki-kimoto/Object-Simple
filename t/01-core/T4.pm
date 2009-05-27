package T4;
use Object::Simple;

sub a1 : Attr { auto_build => 1 }
sub build_a1{
    my $self = shift;
    $self->a1( 1 );
}

sub a2 : Attr { auto_build => 1 }
sub build_a2{ 
    my $self = shift;
    $self->{ a2 } = 1;
}

sub _a4 : Attr { auto_build => 1 }
sub _build_a4{
    my $self = shift;
    $self->_a4( 4 );
}

sub __a5 : Attr { auto_build => 1 }
sub __build_a5{
    my $self = shift;
    $self->__a5( 5 );
}

Object::Simple->end;
