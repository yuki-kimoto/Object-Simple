package M8;
use Object::Simple::Old;

sub m1 : Attr { default => 2 }
sub m2 : Attr { default => 4 }
sub m3 : Attr { default => 1 }

sub m4 {
    return 1;
}

sub m5 {
    return 3;
}

Object::Simple::Old->build_class;

