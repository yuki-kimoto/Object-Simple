package M21;
use Object::Simple;

sub m1 : ClassAttr { auto_build => sub {$_[0]->m1('M21-m1')} }
sub m2 : ClassAttr { auto_build => sub {$_[0]->m2('M21-m2')} }
sub m3 : ClassAttr { auto_build => sub {$_[0]->m3('M21-m3')} }

Object::Simple->build_class;
