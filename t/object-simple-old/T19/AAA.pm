# undef value set
package T19::AAA;
use Object::Simple::Old;

sub m1 : Attr { default => 1 }

sub m2 : Attr { auto_build => \&create_m2 }
sub create_m2 {
    my $self = shift;
    $self->m2(2);
}




Object::Simple::Old->build_class;
