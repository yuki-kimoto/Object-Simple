package T12;
use Object::Simple( base => T1 );

sub _arrange_args{
    my $self = shift;
    return { a => $_[0], b => $_[1], c => 3 };
}

sub _init{
    my ( $self, $args ) = @_;
    
    $self->{ c } = $args->{ c };
}

Object::Simple->end;
