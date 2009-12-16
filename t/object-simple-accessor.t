use Test::More 'no_plan';
use strict;
use warnings;

# Test name
my $test;
sub test {$test = shift}

use lib 't/object-simple-accessor';

my $o;

test 'Import';
use T1;
$o = T1->new;
can_ok($o, qw/attr class_attr hybrid_attr/);

test 'accessor';
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : attr : set and get");
T1->m2(2);
is(T1->m2, 2, "$test : class_attr : set and get");
$o->m3(3);
is($o->m3, 3, "$test : hybrid_attr : set and get object");
T1->m3(4);
is(T1->m3, 4, "$test : hybrid_attr : set and get class");

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
is($o->m6_1, 3, "$test : hybrid_attr : set and get object 1");
T1->m6_1(4);
is(T1->m6_1, 4, "$test : hybrid_attr : set and get class 1");
$o->m6_2(3);
is($o->m6_2, 3, "$test : hybrid_attr : set and get object 2");
T1->m6_2(4);
is(T1->m6_2, 4, "$test : hybrid_attr : set and get class 2");




