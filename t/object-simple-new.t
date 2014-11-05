use Test::More 'no_plan';
use strict;
use warnings;

# Test name
my $test;
sub test {$test = shift}

use lib 't/object-simple';

my $o;

test 'Error';

{
    package T2;
    use base 'Object::Simple';

    eval{__PACKAGE__->attr(m1 => {})};
    Test::More::like($@, qr/Default has to be a code reference or constant value.*T2::m1/,
         'default is not scalar or code ref');

    eval{__PACKAGE__->class_attr('m2', inherit => 'no')};
    Test::More::like($@, qr/\Q'inherit' opiton must be 'scalar_copy', 'array_copy', 'hash_copy', or code reference (T2::m2)/,
                     'invalid inherit options');

    eval{__PACKAGE__->class_attr('m4', no => 1)};
    Test::More::like($@, qr/\Q'no' is invalid option/, "$test : invalid option : class_attr");

    eval{__PACKAGE__->dual_attr('m5', no => 1)};
    Test::More::like($@, qr/\Q'no' is invalid option/, "$test : invalid option : dual_attr");
}

test '-base flag';
use T2;
$o = T2->new;
is($o->x, 1);
is($o->y, 2);

use T3;
$o = T3->new;
is($o->x, 1);
is($o->y, 2);
is($o->z, 3);
{
    package T4;
    use Object::Simple extends => 'T3';
}
$o = T4->new;
is($o->x, 1);
is($o->y, 2);
is($o->z, 3);

{
    package T4_2;
    use Object::Simple extends => 'T3_2';
}
$o = T4_2->new;
is($o->x, 1);
is($o->y, 2);
is($o->z, 3);

