use Test::More 'no_plan';
use strict;
use warnings;

use lib 't/object-simple';

BEGIN {
  $SIG{__WARN__} = sub {
    my $message = shift;
    
    unless ($message =~ /DEPRECATED/ && $message =~ /Object::Simple/) {
      warn $message;
    }
  };
}

# -base flag
{
  {
    use Some::T2;
    my $o = Some::T2->new;
    is($o->x, 1);
    is($o->y, 2);
  }
  
  {
    use T3;
    my $o = T3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T4;
    use Object::Simple -base => 'T3';
  }
  
  {
    my $o = T4->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }

  {
    package T4_2;
    use Object::Simple -base => 'T3_2';
  }
  
  {
    my $o = T4_2->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T4_3;
    use Object::Simple 'T3_2';
  }

  {
    my $o = T4_3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T3_3;
    use T3 -base;
  }
  
  {
    my $o = T3_3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
}


# Test name
my $test;
sub test {$test = shift}

my $o;

test 'new()';
use T1;

$o = T1->new(m1 => 1, m2 => 2);
is_deeply($o, {m1 => 1, m2 => 2}, "$test : hash");
isa_ok($o, 'T1');

$o = T1->new({m1 => 1, m2 => 2});
is_deeply($o, {m1 => 1, m2 => 2}, "$test : hash ref");
isa_ok($o, 'T1');

$o = T1->new;
is_deeply($o, {}, "$test : no arguments");


test 'accessor';
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : attr : set and get");

test 'accessor array';
$o = T1->new;
$o->m4_1(1);
is($o->m4_1, 1, "$test : attr : set and get 1");
$o->m4_2(1);
is($o->m4_2, 1, "$test : attr : set and get 2");

test 'constructor';
$o = T1->new(m1 => 1);
is($o->m1, 1, "$test : hash");

$o = T1->new({m1 => 2});
is($o->m1, 2, "$test : hash ref");


test 'default option';
$o = T1->new;

is($o->m11, 1, "$test : shortcut scalar");
is($o->m12, 9, "$test : shortcut code ref");

test 'array and default';
is($o->m18, 5, "$test : attr : first");
is($o->m19, 5, "$test : attr :second");

test 'Error';

{
    package Some::T2;
    use base 'Object::Simple';

    eval{__PACKAGE__->attr(m1 => {})};
    Test::More::like($@, qr/Default has to be a code reference or constant value.*Some::T2::m1/,
         'default is not scalar or code ref');
}


test 'Method export';
{
    package T3;
    use Object::Simple qw/new attr/;
    __PACKAGE__->attr('m1');
}
$o = T3->new;
$o->m1(1);
is($o->m1, 1, "$test : export attr");


test 'Method export error';
{
    package T4;
    eval "use Object::Simple '-none';";
}
like($@, qr/'-none' is invalid option/, "$test");


# Normal accessor
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : set and get");
is($o->m1(1), $o, "$test : set return");

# Normal accessor with default
{
  {
    # set, get, return
    my $o = T1->new;
    $o->m11(2);
    is($o->m11, 2);
    is($o->m11(2), $o);
  }
  
  {
    # default, default sub reference
    my $o = T1->new;
    is($o->m11, 1);
    is($o->m12, 9);
  }
}

# new()
{
  {
    # from class : hash
    my $o = T1->new(m1 => 1);
    isa_ok($o, 'T1');
    is($o->m1, 1);
  }
  
  {
    # from class : hash ref
    my $o = T1->new({m1 => 1});
    isa_ok($o, 'T1');
    is($o->m1, 1);
  }
  
  {
    # from object : hash
    my $o = $o->new(m1 => 1);
    isa_ok($o, 'T1');
    is($o->m1, 1);
  }
  
  {
    # from object : hash ref
    my $o = $o->new({m1 => 1});
    isa_ok($o, 'T1');
    is($o->m1, 1);
  }
}

{
  # Easy definition
  my $o = T1->new;
  ok($o->can('m33'), $test);
  ok($o->can('m34'), $test);
  is($o->m35, 1, $test);
  is($o->m36, 5, $test);
  is($o->m37, 1, $test);
  is($o->m38, 5, $test);
}

{
  # Attr from object
  my $o = T1->new;
  $o->attr('from_object');
  ok($o->can('from_object'));
}

