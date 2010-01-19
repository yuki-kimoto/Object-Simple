package M9;
use Object::Simple::Old;

sub new {
    my $self = shift->SUPER::new(@_);
    $self->m6(6);
    return $self;
}

sub m1 : Attr { default => 3 }

sub m3 : Attr { default => 2 }
sub m4 : Attr { default => 2 }

sub m5 : Attr { default => 5 }

sub m6 : Attr {}

Object::Simple::Old->build_class;
