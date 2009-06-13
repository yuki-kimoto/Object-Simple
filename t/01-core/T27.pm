package T27;
use Object::Simple;

sub m1 : Attr {
    default => 5,
    trigger => sub{
        my $self = shift;
        $self->m2($self->m1 * 2);
    }
}

sub m2 : Attr {}

sub m3 : Attr { trigger => sub{ $_[0]->m4(exists $_[0]->{'m3'} ? 1 : 0) } }
sub m4 : Attr {}



Object::Simple->build_class;
