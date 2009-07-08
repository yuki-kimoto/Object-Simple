use Test::More tests => 2;

package Parent;
use Object::Simple;

sub children : Attr {}

Object::Simple->build_class;

# 子を表現するクラス
package Child;
use Object::Simple;

sub parent : Attr {}

Object::Simple->build_class;


package main;
{
    my $t = Parent->new(children => 1);
    is($t->children, 1, 'Parent is ok');
}

{
    my $t = Child->new(parent => 1);
    is($t->parent, 1, 'Child is ok');
}
