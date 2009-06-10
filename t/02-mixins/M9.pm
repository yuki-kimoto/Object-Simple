package M9;
use Object::Simple;

sub m1 : Attr { default => 3 }

sub m4 {
    return 2;
}
Object::Simple->end;
