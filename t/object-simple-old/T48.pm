package T48;
use Object::Simple::Old;

sub m1 : Attr      { build => 1 }
sub m2 : Attr      { build => sub { shift->m7 * 2 } }
sub m3 : ClassAttr { build => 3 }
sub m4 : ClassAttr { build => sub { shift->m7 * 4 } }

sub m5 : HybridAttr { build => 5 }
sub m6 : HybridAttr { build => sub { shift->m7 * 6 } }

sub m7 : HybridAttr { build => 7 }

Object::Simple::Old->build_class;
