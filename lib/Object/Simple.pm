package Object::Simple;

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
        my $super =  do {
            no strict 'refs';
            ${"${proto}::ISA"}[0];
        };
        $proto->$attr(eval { $super->can($attr) }
                    ? $inherit->($super->$attr)
                    : ref $default ? $default->($proto) : $default);
    }
}

package Object::Simple;

=head1 NAME

Object::Simple - Generate accessor having default value, and provide constructor


=cut

our $VERSION = '3.0610';

=head1 SYNOPSIS

Class definition.

    package SomeClass;
    
    use base 'Object::Simple';
    
    # Generate accessor
    __PACKAGE__->attr('foo');
    
    # Generate accessor having default value
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

Class accessor.

    # Generate class accessor
    __PACKAGE__->class_attr('foo');
    
    # Generate inheritable class accessor
    __PACKAGE__->class_attr('foo', inherit => 'scalar_copy');
    __PACKAGE__->class_attr('foo', inherit => 'array_copy');
    __PACKAGE__->class_attr('foo', inherit => 'hash_copy');

Dual accessor for both object and class

    # Generate dual accessor
    __PACKAGE__->dual_attr('foo');
    
    # Generate inheritable dual accessor
    __PACKAGE__->dual_attr('foo', inherit => 'scalar_copy');
    __PACKAGE__->dual_attr('foo', inherit => 'array_copy');
    __PACKAGE__->dual_attr('foo', inherit => 'hash_copy');

=head1 DESCRIPTION

=head2 1. Features

L<Object::Simple> is a generator of accessor,
such as L<Class::Accessor>, L<Mojo::Base>, or L<Moose>.
L<Class::Accessor> is simple, but lack offten used features.
C<new()> method can't receive hash arguments.
Default value can't be specified to the accessor.
If multipule values is set through the accssor,
its value is converted to array reference without warnings.

L<Moose> is so complex for many people to use,
and depend on many modules. This is almost another language,
not fit familiar perl syntax.
L<Moose> increase the complexity of projects,
rather than increase production efficiency.
In addition, its complie speed is slow
and used memroy is huge.

L<Object::Simple> is the middle area between L<Class::Accessor>
and complex class builder. Only offten used features is
implemnted.
C<new()> can receive hash or hash reference as arguments.
Default value is specified for the accessor.
Compile speed is fast and used memory is small.
Debugging is natural because the code is easy to read.
L<Object::Simple> is compatible of L<Mojo::Base>
for some people to use easily.

In addition, L<Object::Simple> can generate C<class accessor>
, and C<dual accessor> for both object and class.
This is like L<Class::Data::Inheritable>, but more flexible.
You can specify the way to copy the value of super class.

=head2 2. Generate accessor

At first, you create a class extending L<Object::Simple>
to use methods of L<Object::Simple>.

    package SomeClass;
    
    use base 'Object::Simple';

L<Object::Simple> have C<new()> method to create a new object.
it can receive hash and hash reference as arguments.
    
    my $obj = SomeClass->new;
    my $obj = SomeClass->new(foo => 1, bar => 2);
    my $obj = SomeClass->new({foo => 1, bar => 2});

You can generate accessor by C<attr> method.

    __PACKAGE__->attr('foo');

Using accessor, you can set and get the value.

    # Set the value
    $obj->foo(1);
    
    # Get the value
    my $foo = $obj->foo;

You can specify a default value for accessor.

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

Point3D class, which inherit L<Point> class, and
C<z> attribute, in addition C<x> and C<y>.
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

=head1 3. Concepts of Object-Oriented programing

=head2 Inheritance

I explain Object-Oriented programing essence to use L<Object::Simple> well.

Inheritance is first concept of Object-Oriented programing.

Inheritance.

    +---+
    | A | Base class
    +---+   having metho1() and method2()
      |
    +---+
    | B | Sub class
    +---+   having method3()

Class B inherits Class A,
so B can call all methods of A, in addition to methods of B.
In other words, B can call
C<method1()>, C<method2()>, and C<method3()>

use L<base> module to inherit a class.

    package A;
    
    sub method1 { ... }
    sub method2 { ... }
    
    package B;
    
    use base 'A';
    
    sub method3 { ... }

Perl has useful functions and methods to help Object-Oriented programing.

use C<ref> function to know the object is belong to what class.

    my $class = ref $obj;

use C<isa()> method to know whether a object is belong to a sub class.

    $obj->isa('SomeClass');

use C<can()> method to know whether the object or class can call the method.

    SomeClass->can('method1');
    $obj->can('method1');

=head2 Capsulation

Capsulation is second concept of Object-Oriented programing.
Capsulation means taht
you don't touch internal data directory.
You must use public methods written in documentation.
If you keep this rule, All the thins become simple and secure.

Use only accessor to accesse to the attribute value.

    my $value = $obj->foo;
    $obj->foo(1);

It is bad manner to accesse the value directory.

    my $value = $obj->{foo};
    $obj->{foo} = 1;

=head3 Polymorphism

Polymorphism is third concept of Object-Oriented programing.
Polymorphism is devieded into two concepts,
overloading and overriding.

Perl programer don't care overloading.
Perl is dynamic language,
so subroutine can receive any value.
Overloading is worth for languages having static type variable.

Overriding means that you can change base class's methods in sub class.

    package A;
    
    sub method1 { return 1 }
    
    package B;
    
    use base 'A';
    
    sub method1 { return 2 }

C<method1()> of class A return 1. C<method1> of class B return 2.
That is to say, C<method1()> is overridden in class B

    my $obj_a = A->new;
    $obj_a->method1; # the value is 1
    
    my $obj_b = B->new;
    $obj_b->method1; # the value is 2

If you want to call the method of super class from sub class,
use SUPER pseudo-class.

    package B;
    
    sub metho1 {
        my $self = shift;
        
        my $value = $self->SUPER::method1(); # the value is 1
        
        return 2 + $value;
    }

=head2 4. Special accessors

=head3 Class accessor

You sometimes want to save the value to class, not object.

    my $foo = SomeClass->foo;
    SomeClass->foo(1);

use C<class_attr()>L method if you want to create accessor
for class variable.

    __PACKAGE__->class_attr('foo');

You can also specify default value as same as C<attr()> method.
See section "METHODS class_attr".

The value is saved to class variable C<$CLASS_ATTRS>.
this is hash reference.
"SomeClass->foo(1)" is same as the follwoing one.

    $SomeClass::CLASS_ATTRS->{foo} = 1;

If the value is set in sub class,
the value is saved to sub class, not base class.

Base class.

    package BaseClass;
    
    __PACKAGE__->class_attr('foo');

Sub class.

    package SubClass;
    
    use base 'BaseClass';

C<foo> is called from sub class

    SubClass->foo(1);

This is same as

    SubClass::CLASS_ATTRS->{foo} = 1;

If you want to inherit the value of base class,
use C<inherit> option.

    __PACKAGE__->class_attr('foo', inherit => 'scalar_copy');

The value of C<inherit> option is the way to copy the value.

=over 4

=item *

scalar_copy - normal copy

    my $copy = $value;
    
=item *

array_copy - surface array copy

    my $copy = [@{$value}];

=item *

hash_copy - surface hash copy

    my $copy = {%{$value}};

=back

=head2 Dual accessor

Dual accessor is the accessor havin the feature of
normal accessor and class accessor.

    my $foo = $obj->foo;
    $obj    = $obj->foo(1);
    
    my $foo = SomeClass->foo;
    $class  = SomeClass->foo(1);

If the value is set through the object, the value is saved to the object.
If the value is set through the class, the value is saved to the class.

use C<dual_attr()> method to generate dual accessor.

    __PACKAGE__->dual_attr('foo');

You can also specify default value, and create accessors at once
as same as C<attr()> method. See section "METHODS dual_attr".

C<dual_attr> have C<inherit> option as same as C<class_attr()>,
but one point is difference.
If you try to get the value through the object,
the value is inherited from the class.

    +------------+
    | Some class |
    +------------+
          |
          v
    +------------+
    |    $obj    |
    +------------+

Source code.

    SomeClass->foo(1);
    my $obj = SomeClass->new;
    my $value_of_some_class = $obj->foo;

This can be chained from base class.

    +------------+
    | Base class |
    +------------+
          |
          v
    +------------+
    | Some class |
    +------------+
          |
          v
    +------------+
    |    $obj    |
    +------------+

Base class.

    package BaseClass;
    
    __PACKAGE__->dual_attr('foo', inherit => 'scalar_copy');

Sub class.

    package SubClass;
    
    use base 'BaseClass';

The value is inherited from the base class.

    BaseClass->foo(1);
    my $obj = SubClass->new;
    my $value_of_base_class = $obj->foo;

This tequnique is explained with a example in section
"5. Offten used techniques - Inherit a value from class to object"

=head1 5. Offten used techniques

=head2 Override new() method

C<new()> method is overridden if needed.

B<Example:>

Initialize the object

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

B<Example:>

Change new() arguments
    
    sub new {
        my $self = shift;
        
        $self->SUPER::new(x => $_[0], y => $_[1]);
        
        return $self;
    }

You can pass array to C<new()> method.

    my $point = Point->new(4, 5);

=head2 Inherit the value from class to object

If you want to save the value to the class,
and get the value from the object,
use C<dual_attr()> with C<default> and C<inherit> option.

For example, If you register some finctions to the class,
and call the functions from the object,
create the following class.

    package SomeClass;
    
    __PACKAGE__->dual_attr(
      'functions', default => sub { {} }, inherit => 'hash_copy');
    
    sub register_function {
        my $invocant = shift;
        
        my $functions = ref $_[0] eq 'HASH' ? $_[0] : {@_};
        $invocant->functions({%{$invocant->functions}, %$functions});
        
        return $invocant;
    }
    
    __PACKAGE__->register_function(
        func1 => sub { return 1 }
    );

Fucntions is saved to C<functions> attribute of SomeClass,
and by C<register_function()>, You can register function.

You can call these functions from the object.

    my $obj = SomeClass->new;
    my $ret = $obj->functions->{func1};

This is like "Prototype inheritance of JavaScript", but more flexible.
You can also register functions in sub class and object.

Base class.

    package BaseClass;
    
    # (Code is same as above SomeClass)

Sub class.

    package SubClass;
    
    __PACKAGE->register_function(
       func2 => sub { return 2 }
    );

Object.

    my $obj = SubClass->new;
    $obj->register_function(
        func3 => sub { return 3 }
    );

You can call registered functions from the object

    my $value1 = $obj->functions->{func1};
    my $value2 = $obj->functions->{func2};
    my $value3 = $obj->functions->{func3};

Most practical example is L<Validator::Custom>
and L<Validator::Custom::HTMLForm>.
See also these modules.

=head1 6. More features

=head2 Checking arguments

L<Object::Simple> pay attention to usability.
If wrong number arguments is passed to new() or accessor,
exception is thrown.
    
    # Constructor must receive even number aruments or hash refrence
    my $obj = SomeClass->new(1);
    
    # Accessor must receive only one argument
    $obj->foo(a => 1);

=head2 Import methods

You can import methods of L<Object::Simple>.
This is useful in case you don't want to do multiple inheritance.

    package SomeClass;
    
    use Object::Simple qw/attr class_attr dual_attr/;
    
    __PACKAGE__->attr('foo');

Note that you can't override C<new()> method
because C<new()> method is not inherited from the base class,

=head2 Method chain

Accessor return self-object when it called to set the value,
so you can do method chain.

    $obj->foo(1)->bar(4)->baz(6);

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

Generate accessor. C<attr()> method receive two arguments,
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

=head2 C<class_attr>

    __PACKAGE__->class_attr('foo');
    __PACKAGE__->class_attr([qw/foo bar baz/]);
    __PACKAGE__->class_attr(foo => 1);
    __PACKAGE__->class_attr(foo => sub { {} });

Generate accessor for class variable.
C<class_attr()> method receive two arguments,
accessor name and default value.
If you want to create multipule accessors at once,
specify accessor names as array reference at first argument.
Default value is optional.
If you want to specify refrence or object as default value,
the value must be sub reference
not to share the value with other objects.

Generated class accessor.

    my $value = SomeClass->foo;
    $class    = SomeClass->foo(1);

You can set and get a value.
If a default value is specified and the value is not exists,
you can get default value.
Accessor return class name if a value is set.

Class accessor save the value to the class variable "CLASS_ATTRS".
The folloing two is same.

    SomeClass->foo(1);
    $SomeClass::CLASS_ATTRS->{foo} = 1;

You can delete the value and check existance of it.

    delete $SomeClass::CLASS_ATTRS->{foo};
    exists $SomeClass::CLASS_ATTRS->{foo};

If the value is set from subclass, the value is saved to
the class variable of subclass.

    $SubClass->foo(1);
    $SubClass::CLASS_ATTRS->{foo} = 1;

If you want to inherit the value of super class,
use C<default> and C<inherit> options.

    __PACKAGE__->class_attr(
        'foo', default => sub { {} }, inherit => 'hash_copy');

you must specify the way to copy the value of super class
to C<inherit> option.
this is one of C<scalar_copy>, C<array_copy>, C<hash_copy>,
or sub reference.

C<scalar> copy is normal copy,
C<array_copy> is surface copy of array reference
C<hash_copy> is surface copy of hash reference.
the implementations are the folloing ones.

    # scalar_copy
    my $copy = $value;
    
    # array_copy
    my $copy = [@{$value}];
    
    # hash_copy
    my $copy = {%{$value}};

=head2 C<dual_attr>

    __PACKAGE__->dual_attr('foo');
    __PACKAGE__->dual_attr([qw/foo bar baz/]);
    __PACKAGE__->dual_attr(foo => 1);
    __PACKAGE__->dual_attr(foo => sub { {} });

Generate accessor for both object and class variable.
C<dual_attr()> method receive two arguments,
accessor name and default value.
If you want to create multipule accessors at once,
specify accessor names as array reference at first argument.
Default value is optional.
If you want to specify refrence or object as default value,
the value must be sub reference
not to share the value with other objects.

Generated dual accessor.

    my $value = $obj->foo;
    $obj      = $obj->foo(1);

    my $value = SomeClass->foo;
    $class    = SomeClass->foo(1);

You can set and get a value.
If a default value is specified and the value is not exists,
you can get default value.
Accessor return class name or object if a value is set.

If accessor is called from object,
the value is saved to object.
If accesosr is called from class name,
the value is saved to class variable.
See also description of C<class_attr> method.

C<dual_attr()> method have C<default> and C<inherit> options
as same as C<class_attr()> method have.

    __PACKAGE__->dual_attr(
        'foo', default => sub { {} }, inherit => 'hash_copy');

But one point is different.
If accessor is called from a object, the object
inherit the value of the class.

    SomeClass->foo({name => 1});
    my $obj = SomeClass->new;
    my $foo = $obj->foo;

C<$foo> is C<{name => 1}> because it inherit the value of class.

=head1 EXPORTS


=head1 STABILITY

L<Object::Simple> is now stable.
APIs and the implementations will not be changed in the future.

=head1 BUGS

Please tell me bugs if they are found.

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

