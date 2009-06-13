use Test::More  'no_plan';
use strict;
use warnings;


package T1;
use Object::Simple;
sub m1 : Attr { default => 1 }
Object::Simple->build_class;

package T2;
use Object::Simple(base => 'T1');
sub m2 : Attr { default => 2 }
Object::Simple->build_class;

package T3;
use Object::Simple;
sub m3 : Attr { default => 3 }
Object::Simple->build_class;

package T4;
use Object::Simple;
sub m4 : Attr { default => 4 }
Object::Simple->build_class;

package T5;
use Object::Simple(base => 'T2', mixins => [ 'T3', 'T4' ]);
sub m5 : Attr { default => 5 }
Object::Simple->build_class;

package main;
{
    my $t = T5->new;
    is_deeply($t, { m1 => 1, m2 => 2, m3 => 3, m4 => 4, m5 => 5}, 'test1');
}

{
    my $t = T5->new( m1 => 6, m2 => 7, m3 => 8, m4 => 9, m5 => 10);
    is_deeply($t, {m1 => 6, m2 => 7, m3 => 8, m4 => 9, m5 => 10}, 'test2');
}

package main;
{
    my $t = T10->new;
    is_deeply($t, { m1 => 1, m2 => 2, m3 => 3, m4 => 4, m5 => 5}, 'test3');
}

{
    my $t = T10->new( m1 => 6, m2 => 7, m3 => 8, m4 => 9, m5 => 10);
    is_deeply($t, {m1 => 6, m2 => 7, m3 => 8, m4 => 9, m5 => 10}, 'test4');
}

BEGIN{
    package T10;
    use Object::Simple(base => 'T7', mixins => [ 'T8', 'T9' ]);
    sub m5 : Attr { default => 5 }

    package T9;
    use Object::Simple;
    sub m4 : Attr { default => 4 }

    package T8;
    use Object::Simple;
    sub m3 : Attr { default => 3 }

    package T7;
    use Object::Simple(base => 'T6');
    sub m2 : Attr { default => 2 }

    package T6;
    use Object::Simple;
    sub m1 : Attr { default => 1 }

    Object::Simple->build_class;
}
