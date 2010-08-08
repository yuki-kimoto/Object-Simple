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

Object::Simple - generate accessor with default, and provide constructor

=head1 VERSION

Version 3.0609

=cut

our $VERSION = '3.0609';

=head1 SYNOPSIS

    package YourClass;
    
    use base 'Object::Simple';
    
    # Generate accessor
    __PACKAGE__->attr('x');
    
    # Generate accessor with default (scalar)
    __PACKAGE__->attr(x => 0);
    
    # Generate accessor with default (reference or instance)
    __PACKAGE__->attr(x => sub { [] });
    __PACKAGE__->attr(x => sub { {} });
    __PACKAGE__->attr(x => sub { SomeClass->new });
    
    # Generate accessors at once
    __PACKAGE__->attr([qw/x y z/]);
    
    # Generate accessors with default at once
    __PACKAGE__->attr([qw/x y z/] => 0);
    
    # Generate class accessor
    __PACKAGE__->class_attr('x');
    __PACKAGE__->class_attr(x => 0);
    
    # Generate inheritable class accessor
    __PACKAGE__->class_attr('x', default => 0, inherit => 'scalar_copy');
    __PACKAGE__->class_attr('x', default => sub { [] }, inherit => 'array_copy');
    __PACKAGE__->class_attr('x', default => sub { {} }, inherit => 'hash_copy');
    
    __PACKAGE__->class_attr(
      'x', default => sub { SomeClass->new }, inherit => sub { shift->clone });
    
    # Generate dual accessor, which work as normal accessor or class accessor
    __PACKAGE__->dual_attr('x');
    __PACKAGE__->dual_attr(x => 0);
    
    # Generate inheritable dual accessor
    __PACKAGE__->dual_attr('x', default => 0, inherit => 'scalar_copy');
    __PACKAGE__->dual_attr('x', default => sub { [] }, inherit => 'array_copy');
    __PACKAGE__->dual_attr('x', default => sub { {} }, inherit => 'hash_copy');
    
    __PACKAGE__->dual_attr(
      'x', default => sub { SomeClass->new }, inherit => sub { shift->clone });
    
    package main;
    
    # Constructor new()
    my $obj = YourClass->new;
    my $obj = YourClass->new(x => 1, y => 2);
    my $obj = YourClass->new({x => 1, y => 2});
    
    # Set attribute
    $obj->x(1);
    
    # Setter method chain is available
    $obj->x(1)->y(2);
    
    # Get attribute
    my $x = $obj->x;

=head1 DESCRIPTION

L<Object::Simple> is a accessor generator.
To create a class, you must write many accessors by yourself,

L<Object::Simple> help you to do this work.
a L<Object::Simple> subclass call attr() method to create accessor.
    
    package YourClass;
    
    use base 'Object::Simple';

    # Generate accessor
    __PACKAGE__->attr('x');

L<Object::Simple> also provide a constructor.
new() receive hash or hash reference.

    # Constructor
    my $obj = YourClass->new(x => 1, y => 2);
    my $obj = YourClass->new({x => 1, y => 2});

This instance can call x() to set and get attribute.

    # Set attribute
    $obj->x(1);
    
    # Get attribute
    my $x = $obj->x;
    
Default value for accessor can be specified.
If x() is called at first, the default value is set to the attribute.

    # Generate accessor with default (scalar)
    __PACKAGE__->attr(x => 0);

If you specifiy a reference or instance as default value,
it must be return value of sub reference.
This is requirement not to share the value with more than one instance.

    # Generate accessor with default (reference or instance)
    __PACKAGE__->attr(x => sub { [] });
    __PACKAGE__->attr(x => sub { {} });
    __PACKAGE__->attr(x => sub { SomeClass->new });

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

You can only import accessor generating methods if you need.

    package YourClass;
    
    use Object::Simple qw/attr class_attr dual_attr/;
    
    __PACKAGE__->attr('x');

attr(), class_attr(), and dual_attr() is implemented by closure, not eval,
so memory efficiency is very good.
and the performance of compiling is very fast.

And accessor is optimized not to damage the performance.

L<Object::Simple> pay attention to usability.
If wrong number arguments is passed to new() or accessor,
exception is thrown.
    
    # Exception!
    my $obj = YourClass->new(1); 
    
    # Exception!
    $obj->x(a => 1);

L<Object::Simple>'s attr() is compatible with L<Mojo::Base>'s attr().
L<Mojo::Base> is minimal but enough to do Object Oriented Programing.
If you like L<Mojo::Base>, L<Object::Simple> is good choice for you.

=head1 METHODS

=head2 new

Create instance. the subclass of L<Object::Simple> inherit new() method.
"new" receive hash or hash reference.

    package YourClass;
    
    use base 'Object::Simple';

    my $obj = YourClass->new;
    my $obj = YourClass->new(x => 1, y => 2);
    my $obj = YourClass->new({x => 1, y => 2});

=head2 attr

Generate accessor.
    
    __PACKAGE__->attr('x');
    __PACKAGE__->attr([qw/x y z/]);

You can specify default value for accessor.

    __PACKAGE__->attr(x => 0);
    __PACKAGE__->attr([qw/x y z/] => 0);

If you specifiy a reference or instance as default value,
it must be return value of sub reference.
This is requirement not to share the value with more than one instance.

    __PACKAGE__->attr(x => sub { [] });
    __PACKAGE__->attr(x => sub { {} });
    __PACKAGE__->attr(x => sub { SomeClass->new });

Setter is chained.

    $obj->x(3)->y(4);
    
=head2 class_attr

Generate class accessor.

    __PACKAGE__->class_attr('x');
    __PACKAGE__->class_attr(x => 0);
    __PACKAGE__->class_attr([qw/x y z/]);

Class accessor is called by class, not instance.

    YourClass->x(5);

The value is saved to $CLASS_ATTRS in that class.

If you want to delete the value or check the existence it,
"delete" or "exists" function is available.

    delete $YourClass::CLASS_ATTRS->{x};
    exists $YourClass::CLASS_ATTRS->{x};

If you call class accessor from subclass,
the value is saved to $CLASS_ATTRS in the subclass.
    
    # The value is saved to $YourSubClass::CLASS_ATTRS
    YourSubClass->x(6); 

Class accessor can inherit the value of class variable in super class.

    __PACKAGE__->class_attr('x', default => 0, inherit => 'scalar_copy');
    __PACKAGE__->class_attr('x', default => sub { [] }, inherit => 'array_copy');
    __PACKAGE__->class_attr('x', default => sub { {} }, inherit => 'hash_copy');
    __PACKAGE__->class_attr(
      'x', default => sub { SomeClass->new }, inherit => sub { shift->clone });

scalar_copy, array_copy, hash_copy is the same as the following subroutine.s

    # scalar_copy
    inherit => sub { return $_[0] }
    
    # array_copy
    inherit => sub { return [@{$_[0]}] }
    
    # hash_copy
    inherit => sub { return {%{$_[0]}} }

=head2 dual_attr

Generate dual accessor, which work as normal accessor or class accessor.

    __PACKAGE__->class_attr('x');
    __PACKAGE__->class_attr(x => 0);
    __PACKAGE__->class_attr([qw/x y z/]);

Accessor is called both by instance and class.
If called by instance, the accessor work as normal accessor.
If called by class, the accessor work as class accessor.

    $obj->x(5)
    YourClass->x(5);

Dual accessor can inherit the value of class variable if called by instance,
and the value of class variable in super class if called by class.

    __PACKAGE__->class_attr('x', default => 0, inherit => 'scalar_copy');
    __PACKAGE__->class_attr('x', default => sub { [] }, inherit => 'array_copy');
    __PACKAGE__->class_attr('x', default => sub { {} }, inherit => 'hash_copy');
    __PACKAGE__->dual_attr(
      'x', default => sub { SomeClass->new }, inherit => sub { shift->clone });

scalar_copy, array_copy, hash_copy is the same as the following subroutine.s

    # scalar_copy
    inherit => sub { return $_[0] }
    
    # array_copy
    inherit => sub { return [@{$_[0]}] }
    
    # hash_copy
    inherit => sub { return {%{$_[0]}} }

=head1 STABILITY

L<Object::Simple> is stable.
APIs and the implementation will not be changed from v3.0601.
Only bug fixing will be done if it is found.

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

