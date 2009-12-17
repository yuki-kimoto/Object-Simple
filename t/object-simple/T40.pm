package T40;
use Object::Simple;

sub m1    : Attr   { default => 1 }
sub m1_to : Output { target => 'm1' }

sub m2    : Attr   { default => sub {[1,2]} }
sub m2_to : Output { target => 'm2' }

Object::Simple->build_class;
