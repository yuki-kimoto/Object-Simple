package T37;
use Object::Simple::Old;

sub m1 : ClassAttr {}
sub m2 : ClassAttr { chained => 0 }
sub m3 : ClassAttr { weak => 1 }
sub m4 : ClassAttr { read_only => 1 }
sub m5 : ClassAttr { auto_build => sub { $_[0]->m5(5) } }
sub m6 : ClassAttr { type => 'array', deref => 1 }
sub m7 : ClassAttr { type => 'hash',  deref => 1 }
sub m8 : ClassAttr { trigger => sub{ $_[0]->m9($_[0]->m8 *2) } }
sub m9 : ClassAttr {}

sub m10 : ClassAttr {  type => 'hash', deref => 1,  auto_build => 1 }
sub build_m10 : {
    my $class = shift;
    
    my $super = do {
        no strict 'refs';
        ${"${class}::ISA"}[0];
    };
    
    $class->m10(eval{ $super->m10 } || {});
}

sub add_m10 {
    my $class = shift;
    my $m10 = $class->m10;
    
    my %new_m10 = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my %old_m10 = $class->m10;
    $class->m10(%old_m10, %new_m10);
}

Object::Simple::Old->build_class;

