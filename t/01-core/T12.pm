package T12;
use Object::Simple( base => T1 );

sub _arrange_args{
    my $self = shift;
    return { a => $_[0], b => $_[1], c => 3 };
}

sub _init{
    my ( $self, $args ) = @_;
    
    $self->{ c } = delete $args->{ c };
    my @rest_keys = keys %{ $args };
    if( !@rest_keys ){ $self->{ no_rest } = 1 }
}

Object::Simple->end;
