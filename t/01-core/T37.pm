package T37;
use Object::Simple;

sub m1 : ClassAttr {}
sub m2 : ClassAttr { chained => 0 }
sub m3 : ClassAttr { weak => 1 }
sub m4 : ClassAttr { read_only => 1 }
sub m5 : ClassAttr { auto_build => sub { $_[0]->m5(5) } }
sub m6 : ClassAttr { type => 'array', deref => 1 }
sub m7 : ClassAttr { type => 'hash',  deref => 1 }
sub m8 : ClassAttr { trigger => sub{ $_[0]->m9($_[1]*2) } }
sub m9 : ClassAttr {}

Object::Simple->build_class;

