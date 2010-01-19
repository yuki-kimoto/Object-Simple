package T3_03;
use Object::Simple::Old(base => 'T2_03');

sub new {
    my $self = shift->SUPER::new(@_);
}
sub m3 : Attr {default => 3}
sub m4 : Attr {}

Object::Simple::Old->build_class;

1;