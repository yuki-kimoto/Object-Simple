package M9;
use Object::Simple;

sub m1 : Attr { default => 3 }

sub m4 {
    return 2;
}

sub m5 {
    return 5;
}
Object::Simple->end;
