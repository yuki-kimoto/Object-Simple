package Object::Simple;

our $VERSION = '3.14';

use strict;
use warnings;
use Scalar::Util ();

no warnings 'redefine';

use Carp ();

sub import {
  my $class = shift;
  
  return unless @_;

  # Caller
  my $caller = caller;
  
  # No export syntax
  my $no_export_syntax;
  unless (grep { $_[0] eq $_ } qw/new attr class_attr dual_attr/) {
    $no_export_syntax = 1;
  }
  
  # Inheritance and including role
  if ($no_export_syntax) {
    
    # Option
    my %opt;
    my $base_opt_name;
    if (@_ % 2 != 0) {
      my $base_opt_name = shift;
      if ($base_opt_name ne '-base') {
        Carp::croak "'$base_opt_name' is invalid option(Object::Simple::import())";
      }
      $opt{-base} = undef;
    }
    %opt = (%opt, @_);
    
    # Base class
    my $base_class = delete $opt{-base};
    
    # Check option
    for my $opt_name (keys %opt) {
      Carp::croak "'$opt_name' is invalid option(Object::Simple::import())";
    }
    
    # Export has function
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::has"} = sub { attr($caller, @_) };
    
    # Inheritance
    if ($base_class) {
      my $base_class_path = $base_class;
      $base_class_path =~ s/::|'/\//g;
      require "$base_class_path.pm";
      @{"${caller}::ISA"} = ($base_class);
    }
    else { @{"${caller}::ISA"} = ($class) }
    
    # strict!
    strict->import;
    warnings->import;
  }
  
  # Export methods
  else {
    my @methods = @_;
  
    # Exports
    my %exports = map { $_ => 1 } qw/new attr class_attr dual_attr/;
    
    # Export methods
    for my $method (@methods) {
      
      # Can be Exported?
      Carp::croak("Cannot export '$method'.")
        unless $exports{$method};
      
      # Export
      no strict 'refs';
      *{"${caller}::$method"} = \&{"$method"};
    }
  }
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub attr {
  my ($self, @args) = @_;
  
  my $class = ref $self || $self;
  
  # Fix argument
  unshift @args, (shift @args, undef) if @args % 2;
  
  for (my $i = 0; $i < @args; $i += 2) {
      
    # Attribute name
    my $attrs = $args[$i];
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Default
    my $default = $args[$i + 1];
    
    for my $attr (@$attrs) {

      Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

      # Header (check arguments)
      my $code = "*{\"${class}::$attr\"} = sub {\n  if (\@_ == 1) {\n";

      # No default value (return value)
      unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

      # Default value
      else {

        Carp::croak "Default has to be a code reference or constant value (${class}::$attr)"
          if ref $default && ref $default ne 'CODE';

        # Return value
        $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

        # Return default value
        $code .= "    return \$_[0]{'$attr'} = ";
        $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
      }

      # Store value
      $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

      # Footer (return invocant)
      $code .= "  \$_[0];\n}";

      # We compile custom attribute code for speed
      no strict 'refs';
      warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{OBJECT_SIMPLE_DEBUG};
      Carp::croak "Object::Simple error: $@" unless eval "$code;1";
    }
  }
}

# DEPRECATED!
sub class_attr {
  require Object::Simple::Accessor;
  Object::Simple::Accessor::create_accessors('class_attr', @_)
}

# DEPRECATED!
sub dual_attr {
  require Object::Simple::Accessor;
  Object::Simple::Accessor::create_accessors('dual_attr', @_)
}

=head1 NAME

Object::Simple - Simple class builder(Mojo::Base porting)

=head1 SYNOPSIS

  package SomeClass;
  use Object::Simple -base;
  
  # Create accessor
  has 'foo';
  
  # Create accessor with default value
  has foo => 1;
  has foo => sub { [] };
  has foo => sub { {} };
  has foo => sub { OtherClass->new };
  
  # Create accessors at once
  has [qw/foo bar baz/];
  has [qw/foo bar baz/] => 0;
  
Create object.

  # Create a new object
  my $obj = SomeClass->new;
  my $obj = SomeClass->new(foo => 1, bar => 2);
  my $obj = SomeClass->new({foo => 1, bar => 2});
  
  # Set and get value
  my $foo = $obj->foo;
  $obj->foo(1);
  
  # set-accessor can be changed
  $obj->foo(1)->bar(2);

Inheritance
  
  # Foo.pm
  package Foo;
  use Object::Simple -base;
  
  # Bar.pm
  package Bar;
  use Foo -base;
  
  # Bar.pm (another way to inherit)
  package Bar;
  use Object::Simple -base => 'Foo';

Role(EXPERIMENTAL)
  
  # SomeRole1.pm
  package SomeRole;
  sub bar {
    ...
  }

  # SomeRole2.pm
  package SomeRole;
  sub baz {
    ...
  }
  
  # Foo.pm
  package Foo;
  use Object::Simple -base, with => ['SomeRole1', 'SomeRole2'];
  
  # main.pl
  my $foo = Foo->new;
  $foo->bar;
  $foo->baz;

=head1 DESCRIPTION

L<Object::Simple> is L<Mojo::Base> porting.
you can use L<Mojo::Base> features.

L<Object::Simple> is a generator of accessor method,
such as L<Class::Accessor>, L<Mojo::Base>, or L<Moose>.

L<Class::Accessor> is simple, but lack offten used features.
C<new> method can't receive hash arguments.
Default value can't be specified.
If multipule values is set through the accessor,
its value is converted to array reference without warnings.

Some people find L<Moose> too complex, and dislike that 
it depends on outside modules. Some say that L<Moose> is 
almost like another language and does not fit the familiar 
perl syntax. In some cases, in particular smaller projects, 
some people feel that L<Moose> will increase complexity
and therefore decrease programmer efficiency.
In addition, L<Moose> can be slow at compile-time and 
its memory usage can get large.

L<Object::Simple> is the middle way between L<Class::Accessor>
and complex class builder. Only offten used features is
implemented has no dependency.
L<Object::Simple> is almost same as L<Mojo::Base>.

C<new> method can receive hash or hash reference.
You can specify default value.

If you like L<Mojo::Base>, L<Object::Simple> is good choice.

=head1 GUIDE

=head2 1. Create accessor

At first, you create class.

  package SomeClass;
  use Object::Simple -base;

By using C<-base> option, SomeClass inherit Object::Simple and import C<has> method.

L<Object::Simple> have C<new> method. C<new> method is constructor.
C<new> method can receive hash or hash reference.
  
  my $obj = SomeClass->new;
  my $obj = SomeClass->new(foo => 1, bar => 2);
  my $obj = SomeClass->new({foo => 1, bar => 2});

Create accessor by using C<has> function.

  has 'foo';

If you create accessor, you can set or get attribute value.s

  # Set value
  $obj->foo(1);
  
  # Get value
  my $foo = $obj->foo;

set-accessor can be changed.

  $obj->foo(1)->bar(2);

You can define default value.

  has foo => 1;

If C<foo> attribute value is not exists, default value is used.

  my $foo_default = $obj->foo;

If you want to use reference or object as default value,
default value must be surrounded by code reference.
the return value become default value.

  has foo => sub { [] };
  has foo => sub { {} };
  has foo => sub { SomeClass->new };

You can create multiple accessors at once.

  has [qw/foo bar baz/];
  has [qw/foo bar baz/] => 0;

=head2 Class example

I introduce L<Object::Simple> example.

Point class: two accessor C<x> and C<y>,
and C<clear> method to set C<x> and C<y> to 0.

  package Point;
  use Object::Simple -base;

  has x => 0;
  has y => 0;
  
  sub clear {
    my $self = shift;
    
    $self->x(0);
    $self->y(0);
  }

Use Point class.

  use Point;
  my $point = Point->new(x => 3, y => 5);
  print $point->x;
  $point->y(9);
  $point->clear;

Point3D class: Point3D inherit Point class.
Point3D class has C<z> accessor in addition to C<x> and C<y>.
C<clear> method is overriden to clear C<x>, C<y> and C<z>.

  package Point3D;
  use Point -base;
  
  has z => 0;
  
  sub clear {
    my $self = shift;
    
    $self->SUPER::clear;
    
    $self->z(0);
  }

Use Point3D class.

  use Point3D;
  my $point = Point->new(x => 3, y => 5, z => 8);
  print $point->z;
  $point->z(9);
  $point->clear;

=head2 2. Concepts of Object-Oriented programing

I introduce concepts of Object-Oriented programing

=head3 Inheritance

I explain the essence of Object-Oriented programing.

First concept is inheritance.
Inheritance means that
if Class Q inherit Class P, Class Q use all methods of class P.

  +---+
  | P | Base class
  +---+   have method1 and method2
    |
  +---+
  | Q | Sub class
  +---+   have method3

Class Q inherits Class P,
Q can use all methods of P in addition to methods of Q.

In other words, Q can use
C<method1>, C<method2>, and C<method3>

You can use C<-base> option to inherit class.
  
  # P.pm
  package P;
  use Object::Simple -base;
  
  sub method1 { ... }
  sub method2 { ... }
  
  # Q.pm
  package Q;
  use P -base;
  
  sub method3 { ... }

Perl have useful functions and methods to help Object-Oriented programing.

If you know what class the object is belonged to, use C<ref> function.

  my $class = ref $obj;

If you know what class the object inherits, use C<isa> method.

  $obj->isa('SomeClass');

If you know what method the object(or class) can use, use C<can> method 

  SomeClass->can('method1');
  $obj->can('method1');

=head3 Encapsulation

Second concept is encapsulation.
Encapsulation means that
you don't touch internal data directory.
You must use public method when you access internal data.

Create accessor and use it to keep thie rule.

  my $value = $obj->foo;
  $obj->foo(1);

=head3 Polymorphism

Third concept is polymorphism.
Polymorphism is divided into two concepts,
overload and override

Perl programer don't need to care overload.
Perl is dynamic type language.
Subroutine can receive any value.

Override means that you can change method behavior in sub class.
  
  # P.pm
  package P;
  use Object::Simple -base;
  
  sub method1 { return 1 }
  
  # Q.pm
  package Q;
  use P -base;
  
  sub method1 { return 2 }

P C<method1> return 1. Q C<method1> return 2.
Q C<method1> override P C<method1>.

  # P method1 return 1
  my $obj_a = P->new;
  $obj_p->method1; 
  
  # Q method1 return 2
  my $obj_b = Q->new;
  $obj_q->method1;

If you want to use super class method from sub class,
use SUPER pseudo-class.

  package Q;
  
  sub method1 {
    my $self = shift;
    
    # Call supper class P method1
    my $value = $self->SUPER::method1;
    
    return 2 + $value;
  }

If you understand three concepts,
you have learned Object-Oriented programming primary parts.

=head2 3. Often used techniques

=head3 Override new method

C<new> method can be overridden.

B<Example:>

Initialize the object

  sub new {
    my $self = shift->SUPER::new(@_);
    
    # Initialization
    
    return $self;
  }

B<Example:>

Change arguments of C<new>.
  
  sub new {
    my $self = shift;
    
    $self->SUPER::new(x => $_[0], y => $_[1]);
    
    return $self;
  }

You can pass array to C<new> method.

  my $point = Point->new(4, 5);

=head1 IMPORT OPTIONS

=head2 -base

By using C<-base> option, the class inherit Object::Simple
and import C<has> function.

  package Foo;
  use Object::Simple -base;
  
  has x => 1;
  has y => 2;

strict and warnings is automatically enabled.

You can also use C<-base> option in sub class
to inherit other class.
  
  # Bar inherit Foo
  package Bar;
  use Foo -base;

You can also use the following syntax.

  # Same as above
  package Bar;
  use Object::Simple -base => 'Foo';

=head2 with(EXPERIMENTAL)

  with => 'SomeRole'
  with => ['SomeRole1', 'SomeRole2']

You can include roles by using C<with> option.
  
  # SomeRole1.pm
  package SomeRole1;
  sub foo { ... }
  
  # SomeRole2.pm
  package SomeRole2;
  sub bar { ... }
  
  # SomeClass.pm
  package SomeClass;
  use Object::Simple -base, with => ['SomeRole1', 'SomeRole2'];

Role is class. Role itself should not inherit other class.

By using C<with> option, You can include roles into your class.

Role classes is cloned, and it is inserted into inheritance structure.

  Object::Simple
  |
  SomeRole1(cloned)
  |
  SomeRole2(cloned)
  |
  SomeClass
  
SomeClass use all methods of Object::Simple, SomeRole1, SomeRole2.

=head1 FUNCTIONS

=head2 has

Create accessor.
  
  has 'foo';
  has [qw/foo bar baz/];
  has foo => 1;
  has foo => sub { {} };

Create accessor. C<has> receive
accessor name and default value.
Default value is optional.
If you want to create multipule accessors at once,
specify accessor names as array reference at first argument.

If you want to specify reference or object as default value,
it must be code reference
not to share the value with other objects.

Get and set a attribute value.

  my $foo = $obj->foo;
  $obj->foo(1);

If a default value is specified and the value is not exists,
you can get default value.

If a value is set, the accessor return self object.
So you can set a value repeatedly.

 $obj->foo(1)->bar(2);

You can create all accessors at once.

  has [qw/foo bar baz/],
    pot => 1,
    mer => sub { 5 };

=head1 METHODS

=head2 new

  my $obj = Object::Simple->new(foo => 1, bar => 2);
  my $obj = Object::Simple->new({foo => 1, bar => 2});

Create a new object. C<new> receive
hash or hash reference as arguments.

=head2 attr

  __PACKAGE__->attr('foo');
  __PACKAGE__->attr([qw/foo bar baz/]);
  __PACKAGE__->attr(foo => 1);
  __PACKAGE__->attr(foo => sub { {} });

  __PACKAGE__->attr(
    [qw/foo bar baz/],
    pot => 1,
    mer => sub { 5 }
  );

Create accessor.
C<attr> method usage is equal to C<has> method.

=head1 DEPRECATED FUNCTIONALITY

  class_attr method # will be removed 2017/1/1
  dual_attr method # will be removed 2017/1/1

=head1 BACKWARDS COMPATIBILITY POLICY

If a functionality is DEPRECATED, you can know it by DEPRECATED warnings.
You can check all DEPRECATED functionalities by document.
DEPRECATED functionality is removed after five years,
but if at least one person use the functionality and tell me that thing
I extend one year each time he tell me it.

EXPERIMENTAL functionality will be changed without warnings.

(This policy was changed at 2011/10/22)

=head1 BUGS

Tell me the bugs
by mail or github L<http://github.com/yuki-kimoto/Object-Simple>

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2014 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

