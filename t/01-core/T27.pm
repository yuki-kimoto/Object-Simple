package T27;
use Object::Simple;
use Scalar::Util qw(isweak);

sub m1 : Attr {
    default => 5,
    trigger => sub{
        my ($self) = @_;
        $self->m2($self->m1 * 2);
    }
}

sub m2 : Attr {}

sub m3 : Attr { trigger => sub{ $_[0]->m4(exists $_[0]->{'m3'} ? 1 : 0) } }
sub m4 : Attr {}

sub m5 : Attr { weak => 1, trigger => sub { $_[0]->m6(1) if isweak $_[0]->{'m5'} } }
sub m6 : Attr {}



Object::Simple->build_class;
