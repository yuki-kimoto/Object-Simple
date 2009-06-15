package M9;
use Object::Simple;

sub new {
    bless { m1 => 10 }, 'M9';
}

sub m1 : Attr { default => 3 }

sub m3 : Attr { default => 2 }
sub m4 : Attr { default => 2 };

sub m5 : Attr { default => 5 };

Object::Simple->build_class;
