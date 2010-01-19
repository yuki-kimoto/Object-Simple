package M15;
use Object::Simple::Old(mixins => ['M16']);
use File::Basename 'fileparse';

sub m1 : Attr { default => 1 }

Object::Simple::Old->build_class;
