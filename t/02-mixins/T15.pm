package T15;
use Object::Simple( base => 'B4', mixins => ['M18', 'M19']);

sub m1 {
    my $self = shift;
    return Object::Simple->mixin_methods('m1')->[-1]->($self, 1);
}

sub m2 {
    my $self = shift;
    return Object::Simple->mixin_methods('m2')->[-1]->($self, 1);
}

sub m3 {
    my $self = shift;
    my $methods = Object::Simple->mixin_methods('m3');
    return @$methods ? $methods->[-1]->($self, 1) : $self->SUPER::m3(1);
}

sub m4 {
    my $self = shift;
    my $methods = Object::Simple->mixin_methods('m4');
    return @$methods ? $methods->[-1]->($self, 1) : $self->SUPER::m4(1);
}

sub m5 : Attr {}

sub new {
    my $self = shift;
    my $methods = Object::Simple->mixin_methods('new');
    return @$methods ? $methods->[-1]->($self, m5 => 5) : $self->SUPER::new(m5 => 5);
}

sub m7 {
    my $self = shift;
    return $self->Object::Simple::call_mixin('M19', 'm7', 1, 2);
}

sub m8 {
    my $self = shift;
    return $self->Object::Simple::call_mixin('NoExist', 'm7');
}

sub m9 {
    my $self = shift;
    return $self->Object::Simple::call_mixin('M19', 'no_exist');
}

sub m10 {
    my $self = shift;
    return $self->Object::Simple::call_mixin;
}

sub m11 {
    my $self = shift;
    return $self->Object::Simple::call_mixin('M19');
}


sub M19 : Attr {}
sub M18 : Attr {}
sub B4  : Attr {}
sub B5  : Attr {}


Object::Simple->build_class;
