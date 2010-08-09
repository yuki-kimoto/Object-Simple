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

our $VERSION = '3.0609';

=head1 SYNOPSIS

Class definition.

    package SomeClass;
    
    use base 'Object::Simple';
    
    # Generate accessor
    __PACKAGE__->attr('foo');
    
    # Generate accessor with default
    __PACKAGE__->attr(foo => 0);
    __PACKAGE__->attr(foo => sub { [] });
    __PACKAGE__->attr(foo => sub { {} });
    __PACKAGE__->attr(foo => sub { OtherClass->new });
    
    # Generate accessors at once
    __PACKAGE__->attr([qw/foo bar baz/]);
    __PACKAGE__->attr([qw/foo bar baz/] => 0);

Use the class

    # Constructor
    my $obj = SomeClass->new(foo => 1, bar => 2);
    my $obj = SomeClass->new({foo => 1, bar => 2});
    
    # Get attribute
    my $foo = $obj->foo;
    
    # Set attribute
    $obj->x(1);

Class accessor. Accessor for class variable.

    # Generate class accessor
    __PACKAGE__->class_attr('foo');
    __PACKAGE__->class_attr(foo => 0);
    
    # Generate inheritable class accessor
    __PACKAGE__->class_attr(
        'foo', default => 0, inherit => 'scalar_copy');
    
    __PACKAGE__->class_attr(
        'foo', default => sub { [] }, inherit => 'array_copy');
    
    __PACKAGE__->class_attr(
        'foo', default => sub { {} }, inherit => 'hash_copy');
    
    __PACKAGE__->class_attr(
        'foo',
        default => sub { OtherClass->new },
        inherit => sub { shift->clone }
    );

Dual accessor. Accessor for both object and class variable.

    # Generate dual accessor
    __PACKAGE__->dual_attr('foo');
    __PACKAGE__->dual_attr(foo => 0);
    
    # Generate inheritable dual accessor
    __PACKAGE__->dual_attr(
        'foo', default => 0, inherit => 'scalar_copy');
    
    __PACKAGE__->dual_attr(
        'foo', default => sub { [] }, inherit => 'array_copy');
    
    __PACKAGE__->dual_attr(
        'foo', default => sub { {} }, inherit => 'hash_copy');
    
    __PACKAGE__->dual_attr(
        'foo', 
        default => sub { OtherClass->new }, 
        inherit => sub { shift->clone }
    );

=head1 DESCRIPTIONS

=head2 1. Features

L<Object::Simple> is a generator of accessor,
such as L<Class::Accessor>, L<Mojo::Base>, or L<Moose>
L<Class::Accessor> is simple, but it lack offten used features.
C<new()> method can't receive hash arguments.
Default value can't be specified to accessor generating method.
If multipul value is set by accssor,
its value is converted to array reference without warnings.

L<Moose> is so complex for many people to use,
and depend on many modules. This is almost another language,
not fit familiar perl syntax.
L<Moose> increase the complexity of projects,
rather than increase production eficiency.
In addition, its complie speed is slow
and the used memroy is huge.

L<Object::Simple> is the middle area between L<Class::Accessor>
and complex class builder. Only offten used features is
implemnted.
This module is compatible of L<Mojo::Base>
for many people to use easily.
You can define default value for accessor,
and define class accessor.
This is like L<Class::Data::Inheritable>, but more useful
because you can specify method to copy the value of super class.
Compile speed is fast and the used memory is small.
Debuggin is easy.

=head2 2. Basic usage

    package SomeClass;
    
    use base 'Object::Simple';

    __PACKAGE__->attr('foo');

L<Object::Simple> also provide a constructor.
new() receive hash or hash reference.

    # Constructor
    my $obj = SomeClass->new(foo => 1, bar => 2);
    my $obj = SomeClass->new({foo => 1, bar => 2});

This instance can call x() to set and get attribute.

    # Set attribute
    $obj->foo(1);
    
    # Get attribute
    my $foo = $obj->foo;
    
Default value for accessor can be specified.
If C<foo()> is called at first, the default value is set to the attribute.

    # Generate accessor with default
    __PACKAGE__->attr(foo => 0);

If you specifiy a reference or instance as default value,
it must be return value of sub reference.
This is requirement not to share the value with more than one instance.

    # Generate accessor with default (reference or instance)
    __PACKAGE__->attr(foo => sub { [] });
    __PACKAGE__->attr(foo => sub { {} });
    __PACKAGE__->attr(foo => sub { SomeClass->new });

I wrote some examples, Point and Point3D class.
Point has two accessor x() and y(), and method clear().

Point3D is subclass of Point.
Point3D has three accessor x(), y(), z(), and method clear()
which is overridden.

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

You can override new() to initialize the instance or arrange arguments.
To call super class new(), you can use SUPER pseudo-class.

Initialize instance:

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

Arrange arguments:
    
    sub new {
        my $self = shift;
        
        $self->SUPER::new(x => $_[0], y => $_[1]);
        
        return $self;
    }

L<Object::Simple> pay attention to usability.
If wrong number arguments is passed to new() or accessor,
exception is thrown.
    
    # Constructor must receive even number aruments or hash refrence
    my $obj = SomeClass->new(1); # Exception!
    
    # Accessor must receive only one argument
    $obj->x(a => 1); # Exception!

You can only import accessor generator method.

    package SomeClass;
    
    use Object::Simple qw/attr class_attr dual_attr/;
    
    __PACKAGE__->attr('foo');

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
    __PACKAGE__->attr(foo => 0);
    __PACKAGE__->attr(foo => sub { {} });

Generate accessor. C<attr()> method receive two arguments,
accessor name and default value.
If you want to create multipul accessors at once,
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
    __PACKAGE__->class_attr(foo => 0);
    __PACKAGE__->class_attr(foo => sub { {} });

Generate accessor for class variable.
C<class_attr()> method receive two arguments,
accessor name and default value.
If you want to create multipul accessors at once,
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
    __PACKAGE__->dual_attr(foo => 0);
    __PACKAGE__->dual_attr(foo => sub { {} });

Generate accessor for both object and class variable.
C<dual_attr()> method receive two arguments,
accessor name and default value.
If you want to create multipul accessors at once,
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

