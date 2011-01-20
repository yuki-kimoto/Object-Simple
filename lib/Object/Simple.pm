package Object::Simple;

our $VERSION = '3.0616';

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
        
        foreach my $attr (@$attrs) {

            Carp::croak("'default' option must be scalar " . 
                        "or code ref (${class}::$attr)")
              unless !ref $default || ref $default eq 'CODE';

        # Code
        my $code;
        if (defined $default && ref $default) {



$code = sub {

    if(@_ > 1) {
        Carp::croak qq{One argument must be passed to "${class}::$attr()"}
          if @_ > 2;
        
        $_[0]->{$attr} = $_[1];
        
        return $_[0];
    }

    return $_[0]->{$attr} = $default->($_[0]) if ! exists $_[0]->{$attr};
    return $_[0]->{$attr};
}

        }
        elsif (defined $default && ! ref $default) {



$code = sub {
    if(@_ > 1) {
        Carp::croak qq{One argument must be passed to "${class}::$attr()"}
          if @_ > 2;
        
        $_[0]->{$attr} = $_[1];
        
        return $_[0];
    }
    return $_[0]->{$attr} = $default if ! exists $_[0]->{$attr};
    return $_[0]->{$attr};
}



    }
    else {



$code = sub {

    if(@_ > 1) {
        
        Carp::croak qq{One argument must be passed to "${class}::$attr()"}
          if @_ > 2;
        
        $_[0]->{$attr} = $_[1];
        
        return $_[0];
    }

    return $_[0]->{$attr};
}



    }
            
            no strict 'refs';
            *{"${class}::$attr"} = $code;
        }
    }
}

# Deprecated methods
use Object::Simple::Accessor;
sub class_attr { Object::Simple::Accessor::create_accessors('class_attr', @_) }
sub dual_attr  { Object::Simple::Accessor::create_accessors('dual_attr',  @_) }

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
    
    # More easily
    __PACKAGE__->attr(
        [qw/foo bar baz/],
        some => 1,
        other => sub { 5 }
    );

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

See L<Object::Simple::Guides> to know detals.

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

You can set and get a value.

    my $value = $obj->foo;
    $obj      = $obj->foo(1);

If a default value is specified and the value is not exists,
you can get default value.
Accessor return self object if a value is set.

You can create accessors more easy way.

    __PACKAGE__->attr(
        [qw/foo bar baz/],
        pot => 1,
        mer => sub { 5 }
    );

First argument are accessors without default.
Rest arguments are accessors with default.

=head1 Guildes

L<Object::Simple::Guides>

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

