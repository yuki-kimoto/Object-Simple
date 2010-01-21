use Test::More 'no_plan';
use strict;
use warnings;

# Test name
my $test;
sub test {$test = shift}

use lib 't/object-simple-base';

my $o;

test 'methods';
use T1;
$o = T1->new;
can_ok($o, qw/attr class_attr dual_attr/);

test 'accessor';
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : attr : set and get");
T1->m2(2);
is(T1->m2, 2, "$test : class_attr : set and get");
$o->m3(3);
is($o->m3, 3, "$test : dual_attr : set and get object");
T1->m3(4);
is(T1->m3, 4, "$test : dual_attr : set and get class");

test 'accessor array';
$o = T1->new;
$o->m4_1(1);
is($o->m4_1, 1, "$test : attr : set and get 1");
$o->m4_2(1);
is($o->m4_2, 1, "$test : attr : set and get 2");
T1->m5_1(2);
is(T1->m5_1, 2, "$test : class_attr : set and get 1");
T1->m5_2(2);
is(T1->m5_2, 2, "$test : class_attr : set and get 2");
$o->m6_1(3);
is($o->m6_1, 3, "$test : dual_attr : set and get object 1");
T1->m6_1(4);
is(T1->m6_1, 4, "$test : dual_attr : set and get class 1");
$o->m6_2(3);
is($o->m6_2, 3, "$test : dual_attr : set and get object 2");
T1->m6_2(4);
is(T1->m6_2, 4, "$test : dual_attr : set and get class 2");


test 'constructor';
$o = T1->new(m1 => 1);
is($o->m1, 1, "$test : hash");

$o = T1->new({m1 => 2});
is($o->m1, 2, "$test : hash ref");


test 'build option';
$o = T1->new;
is($o->m7, 7, "$test : single");
is($o->m8_1, '8', "$test : multi 1");
is($o->m8_2, '8', "$test : multi 2");

is(T1->m9, 9, "$test : class_attr");
is($o->m10, 10, "$test : dual_attr : object");
is(T1->m10, 10, "$test : dual_attr : class");

test 'dual_attr';
is_deeply(T1_2->m17, {a => 1}, "$test : subclass 1 : class");

$o = T1_2->new;
is_deeply($o->m17, {a => 1}, "$test : subclass 1 : object");

$o->m17->{b} = 1;
is_deeply(T1_2->m17, {a => 1}, "$test : subclass : no effect");

T1_2->m17->{c} = 1;
is_deeply(T1_3->m17, {a => 1, c => 1}, "$test :subclass 2 : class");
$o = T1_3->new;
is_deeply($o->m17, {a => 1, c => 1}, "$test :subclass 2 : object");

