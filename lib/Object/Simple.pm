package Object::Simple;

our $VERSION = '3.0613';

use strict;
use warnings;

use Carp ();

sub import {
    my ($self, @methods) = @_;
    
    # Caller
    my $caller = caller;
    
    # Exports
    my %exports = map { $_ => 1 } qw/new attr class_attr dual_attr/;
    
    # Export methods
    foreach my $method (@methods) {
        
        # Can be Exported?
        Carp::croak("Cannot export '$method'.")
          unless $exports{$method};
        
        # Export
        no strict 'refs';
        *{"${caller}::$method"} = \&{"$method"};
    }
}

sub new {
    my $class = shift;
    
    return bless {%{$_[0]}}, ref $class || $class
      if ref $_[0] eq 'HASH';
    
    Carp::croak(qq{Hash reference or even number arguments } . 
                qq{must be passed to "${class}::new()"})
      if @_ % 2;
    
    return bless {@_}, ref $class || $class;
}

sub attr       { Object::Simple::Accessor::create_accessors('attr',       @_) }

# Deprecated methods
sub class_attr { Object::Simple::Accessor::create_accessors('class_attr', @_) }
sub dual_attr  { Object::Simple::Accessor::create_accessors('dual_attr',  @_) }

package Object::Simple::Accessor;

use strict;
use warnings;

use Carp 'croak';

sub create_accessors {
    my ($type, $class, $attrs, @options) = @_;
    
    # To array
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Arrange options
    my $options = @options > 1 ? {@options} : {default => $options[0]};
    
    # Check options
    foreach my $oname (keys %$options) {
        croak "'$oname' is invalid option"
         if  !($oname eq 'default' || $oname eq 'inherit')
           || ($type eq 'attr' && $oname ne 'default');
    }
    
    # Create accessors
    foreach my $attr (@$attrs) {
        
        # Create accessor
        my $code = $type eq 'attr'
                 ? create_accessor($class, $attr, $options)
                 
                 : $type eq 'class_attr'
                 ? create_class_accessor($class, $attr, $options)
                 
                 : $type eq 'dual_attr'
                 ? create_dual_accessor($class, $attr, $options)
                 
                 : undef;
        
        # Import
        no strict 'refs';
        *{"${class}::$attr"} = $code;
    }
}

sub create_accessor {
    my ($class, $attr, $options, $type) = @_;
    
    # Options
    my $default = $options->{default};
    my $inherit = $options->{inherit} || '';
    
    if ($inherit) {
        
        # Rearrange Inherit option
        $options->{inherit} = $inherit eq 'scalar_copy' ? sub { $_[0]      }
                            : $inherit eq 'array_copy'  ? sub { [@{$_[0]}] }
                            : $inherit eq 'hash_copy'   ? sub { return {%{$_[0]}} }
                            : undef
          unless ref $inherit eq 'CODE';
        
        # Check inherit options
        croak "'inherit' opiton must be 'scalar_copy', 'array_copy', " .
              "'hash_copy', or code reference (${class}::$attr)"
          unless $options->{inherit};
    }

    # Check default option
    croak "'default' option must be scalar or code ref (${class}::$attr)"
      unless !ref $default || ref $default eq 'CODE';

    my $code;
    # Class Accessor
    if (($type || '') eq 'class') {
        
        # With inherit option
        if ($inherit) {





            return sub {
                
                my $self = shift;
                
                croak "${class}::$attr must be called from class."
                  if ref $self;
                
                my $class_attrs = do {
                    no strict 'refs';
                    ${"${self}::CLASS_ATTRS"} ||= {};
                };
                
                inherit_attribute($self, $attr, $options)
                  if @_ == 0 && ! exists $class_attrs->{$attr};
                
                if(@_ > 0) {
                
                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $class_attrs->{$attr} = $_[0];
                    
                    return $self;
                }
                
                return $class_attrs->{$attr};
            };





        }
        
        # With default option
        elsif (defined $default) {





            return sub {
                
                my $self = shift;
                
                croak "${class}::$attr must be called from class."
                  if ref $self;

                my $class_attrs = do {
                    no strict 'refs';
                    ${"${self}::CLASS_ATTRS"} ||= {};
                };
                
                $class_attrs->{$attr} = ref $default ? $default->($self) : $default
                  if @_ == 0 && ! exists $class_attrs->{$attr};
                
                if(@_ > 0) {
                    
                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $class_attrs->{$attr} = $_[0];
                    
                    return $self;
                }
                
                return $class_attrs->{$attr};

            };





        }
        
        # Without option
        else {





            return sub {
                
                my $self = shift;
                
                croak "${class}::$attr must be called from class."
                  if ref $self;

                my $class_attrs = do {
                    no strict 'refs';
                    ${"${self}::CLASS_ATTRS"} ||= {};
                };
                
                if(@_ > 0) {
                
                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $class_attrs->{$attr} = $_[0];
                    
                    return $self;
                }
                
                return $class_attrs->{$attr};
            };





        }
    }
    
    # Normal accessor
    else {
    
        # With inherit option
        if ($inherit) {





            return sub {
                
                my $self = shift;
                
                inherit_attribute($self, $attr, $options)
                  if @_ == 0 && ! exists $self->{$attr};
                
                if(@_ > 0) {
                
                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $self->{$attr} = $_[0];
                    
                    return $self;
                }
                
                return $self->{$attr};
            };






        }
        
        # With default option
        elsif (defined $default) {





            return sub {
                
                my $self = shift;
                
                $self->{$attr} = ref $default ? $default->($self) : $default
                  if @_ == 0 && ! exists $self->{$attr};
                
                if(@_ > 0) {
                    
                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $self->{$attr} = $_[0];
                    
                    return $self;
                }
                
                return $self->{$attr};
            };





        }
        
        # Without option
        else {





            return sub {
                
                my $self = shift;
                
                if(@_ > 0) {

                    croak qq{One argument must be passed to "${class}::$attr()"}
                      if @_ > 1;
                    
                    $self->{$attr} = $_[0];

                    return $self;
                }

                return $self->{$attr};
            };





        }
    }
}

sub create_class_accessor  { create_accessor(@_, 'class') }

sub create_dual_accessor {

    # Create dual accessor
    my $accessor       = create_accessor(@_);
    my $class_accessor = create_class_accessor(@_);
    
    return sub { ref $_[0] ? $accessor->(@_) : $class_accessor->(@_) };
}

sub inherit_attribute {
    my ($proto, $attr, $options) = @_;
    
    # Options
    my $inherit = $options->{inherit};
    my $default = $options->{default};

    # Called from a object
    if (my $class = ref $proto) {
        $proto->{$attr} = $inherit->($class->$attr);
    }
    
    # Called from a class
    else {
        my $base =  do {
            no strict 'refs';
            ${"${proto}::ISA"}[0];
        };
        $proto->$attr(eval { $base->can($attr) }
                    ? $inherit->($base->$attr)
                    : ref $default ? $default->($proto) : $default);
    }
}

package Object::Simple;

=head1 NAME

Object::Simple - Generate accessor having default value, and provide constructor

=head1 SYNOPSIS

Class definition.

    package SomeClass;
    
    use base 'Object::Simple';
    
    # Generate a accessor
    __PACKAGE__->attr('foo');
    
    # Generate a accessor having default value
    __PACKAGE__->attr(foo => 1);
    __PACKAGE__->attr(foo => sub { [] });
    __PACKAGE__->attr(foo => sub { {} });
    __PACKAGE__->attr(foo => sub { OtherClass->new });
    
    # Generate accessors at once
    __PACKAGE__->attr([qw/foo bar baz/]);
    __PACKAGE__->attr([qw/foo bar baz/] => 0);

Use the class

    # Constructor
    my $obj = SomeClass->new;
    my $obj = SomeClass->new(foo => 1, bar => 2);
    my $obj = SomeClass->new({foo => 1, bar => 2});
    
    # Get the value
    my $foo = $obj->foo;
    
    # Set the value
    $obj->foo(1);

=head1 DESCRIPTION

L<Object::Simple> is a generator of accessor,
such as L<Class::Accessor>, L<Mojo::Base>, or L<Moose>.
L<Class::Accessor> is simple, but lack offten used features.
C<new()> method can't receive hash arguments.
Default value can't be specified.
If multipule values is set through the accssor,
its value is converted to array reference without warnings.

L<Moose> is too complex for many people to use,
and depends on many modules. L<Moose> is almost another language,
and don't fit familiar perl syntax.
L<Moose> increase the complexity of projects,
rather than increase production efficiency.
In addition, its complie speed is slow
and used memroy is large.

L<Object::Simple> is the middle area between L<Class::Accessor>
and complex class builder. Only offten used features is
implemented.
C<new()> can receive hash or hash reference as arguments.
You can specify default value for the accessor.
Compile speed is fast and used memory is small.
Debugging is easy.
And L<Object::Simple> is compatible of L<Mojo::Base>

If you know the detail of L<Object::Simple>, see section L</"GUIDES">

=head1 METHODS

=head2 C<new>

    my $obj = Object::Simple->new(foo => 1, bar => 2);
    my $obj = Object::Simple->new({foo => 1, bar => 2});

Create a new object. C<new()> method receive
hash or hash reference as arguments.

=head2 C<attr>

Generate accessor.
    
    __PACKAGE__->attr('foo');
    __PACKAGE__->attr([qw/foo bar baz/]);
    __PACKAGE__->attr(foo => 1);
    __PACKAGE__->attr(foo => sub { {} });

Generate accessor. C<attr()> method receive
accessor name and default value.
If you want to create multipule accessors at once,
specify accessor names as array reference at first argument.
Default value is optional.
If you want to specify refrence or object as default value,
the value must be sub reference
not to share the value with other objects.

Generated accessor.

    my $value = $obj->foo;
    $obj      = $obj->foo(1);

You can set and get a value.
If a default value is specified and the value is not exists,
you can get default value.
Accessor return self object if a value is set.

=head1 GUIDES

=head2 1. Generate accessor

At first, you create a class extending L<Object::Simple>
to use methods of L<Object::Simple>.

    package SomeClass;
    
    use base 'Object::Simple';

L<Object::Simple> have C<new()> method. This is a constructor.
It can receive hash and hash reference as arguments.
    
    my $obj = SomeClass->new;
    my $obj = SomeClass->new(foo => 1, bar => 2);
    my $obj = SomeClass->new({foo => 1, bar => 2});

You can generate accessor by C<attr()> method.

    __PACKAGE__->attr('foo');

You can set and get the value by accessor.

    # Set the value
    $obj->foo(1);
    
    # Get the value
    my $foo = $obj->foo;

You can specify a default value for the accessor.

    __PACKAGE__->attr(foo => 1);

If the value of C<foo> is not exists and C<foo()> is called,
You can get the default value.

    my $default_value = $obj->foo;

If you want to specify a reference or object as default value,
it must be sub reference, whose return value is the default value.
This is requirment not to share the default value with other objects.

    __PACKAGE__->attr(foo => sub { [] });
    __PACKAGE__->attr(foo => sub { {} });
    __PACKAGE__->attr(foo => sub { SomeClass->new });

You can generate accessors at once.

    __PACKAGE__->attr([qw/foo bar baz/]);
    __PACKAGE__->attr([qw/foo bar baz/] => 0);

B<Example:>

I show a example to understand L<Object::Simple> well.

Point class, which have two attribute, C<x> and C<y>,
and C<clear()> method to set C<x> and C<y> to 0.

    package Point;
    
    use strict;
    use warnings;
    
    use base 'Object::Simple';

    __PACKAGE__->attr(x => 0);
    __PACKAGE__->attr(y => 0);
    
    sub clear {
        my $self = shift;
        
        $self->x(0);
        $self->y(0);
    }

Point3D class, which inherit L<Point> class.
This class has C<z> attribute in addition to C<x> and C<y>.
C<clear()> method is overridden to clear C<x>, C<y> and C<z>.
    
    package Point3D;
    
    use strict;
    use warnings;
    
    use base 'Point';
    
    __PACKAGE__->attr(z => 0);
    
    sub clear {
        my $self = shift;
        
        $self->SUPER::clear();
        
        $self->z(0);
    }

=head2 2. Concepts of Object-Oriented programing

=head3 Inheritance

I explain the essence of Object-Oriented programing
to use L<Object::Simple> well.

First concept of Object-Oriented programing is Inheritance.
Inheritance means that
If Class Q inherit Class P, Class Q can call all method of class P.

    +---+
    | P | Base class
    +---+   having method1() and method2()
      |
    +---+
    | Q | Sub class
    +---+   having method3()

Class Q inherits Class P,
so Q can call all methods of P in addition to methods of Q.
In other words, Q can call
C<method1()>, C<method2()>, and C<method3()>

To inherit a class, use L<base> module.

    package P;
    
    sub method1 { ... }
    sub method2 { ... }
    
    package Q;
    
    use base 'P';
    
    sub method3 { ... }

Perl has useful functions and methods to help Object-Oriented programing.

To know the object is belong to what class, use C<ref()> function.

    my $class = ref $obj;

To know whether the object inherits the specified class, use C<isa()> method.

    $obj->isa('SomeClass');

To know whether the object(or class)
can call the specified method,
use C<can()> method 

    SomeClass->can('method1');
    $obj->can('method1');

=head3 Capsulation

Second concept of Object-Oriented programing is capsulation.
Capsulation means that
you don't touch internal data directory.
You must use public methods in documentation.
If you keep this rule, All the things become simple.

To keep this rule,
Use accessor to get and set to the value.

    my $value = $obj->foo;
    $obj->foo(1);

To access the value directory is bad manner.

    my $value = $obj->{foo}; # Bad manner!
    $obj->{foo} = 1;         # Bad manner!

=head3 Polymorphism

Third concept Object-Oriented programing is polymorphism.
Polymorphism is devieded into two concepts,
overloading and overriding.

Perl programer don't have to care overloading.
Perl is dynamic language,
so subroutine can receive any value.
Overloading is worth for languages having static type variable,
like C++ or Java.

Overriding means that in sub class you can change the process of the base class's method.

    package P;
    
    sub method1 { return 1 }
    
    package Q;
    
    use base 'P';
    
    sub method1 { return 2 }

C<method1()> of class P return 1. C<method1()> of class Q return 2.
That is to say, C<method1()> is overridden in class Q.

    my $obj_a = P->new;
    $obj_p->method1; # Return value is 1
    
    my $obj_b = Q->new;
    $obj_q->method1; # Return value is 2

If you want to call the method of base class from sub class,
use SUPER pseudo-class.

    package Q;
    
    sub method1 {
        my $self = shift;
        
        my $value = $self->SUPER::method1(); # return value is 1
        
        return 2 + $value;
    }

If you understand only these three concepts,
you can do enough powerful Object-Oriented programming.
and source code is readable for other language users.

=head2 3. Offten used techniques

=head3 Override new() method

C<new()> method is overridden if needed.

B<Example:>

Initialize the object

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

B<Example:>

Change arguments of C<new()>.
    
    sub new {
        my $self = shift;
        
        $self->SUPER::new(x => $_[0], y => $_[1]);
        
        return $self;
    }

You can pass array to C<new()> method by overridden C<new()> method.

    my $point = Point->new(4, 5);

=head2 4. Other features

=head3 Strict arguments check

L<Object::Simple> pay attention to the usability.
If wrong number arguments is passed to C<new()> method,
exception is thrown.
    
    my $obj = SomeClass->new(1); # Exception!

as is the accessor.

    $obj->foo(a => 1); # Execption!

=head3 Import methods

You can import methods of L<Object::Simple>.
This is useful in case you don't want to use multiple inheritance.

    package SomeClass;
    
    use Object::Simple qw/new attr/;
    
    __PACKAGE__->attr('foo');

Note that you can't override C<new()> method
because C<new()> method is imported in the class,
not inherited from base class.

=head3 Method chain

Method chain is available because
accessor return self-object when it is called to set the value,

    $obj->foo(1)->bar(4)->baz(6);

=head1 STABILITY

L<Object::Simple> is stable.
APIs and the implementations will not be changed in the future.

=head1 DEPRECATED

C<class_attr> and C<dual_attr> is deprecated because
this is not good practice in Object Oriented programming.
To know the usages, see old documentation before 3.0612.

=head1 BUGS

Tell me the bugs
by mail or github L<http://github.com/yuki-kimoto/Object-Simple>

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

