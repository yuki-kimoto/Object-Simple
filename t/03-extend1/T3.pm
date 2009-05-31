package T3;
use Object::Simple(base => T2);

sub new {
    my $self = shift->SUPER::new(@_);
}
sub m3 : Attr {default => 3}
sub m4 : Attr {}

Object::Simple->end;

1;