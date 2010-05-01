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
    
    # Instantiate hash reference
    return bless {%{$_[0]}}, ref $class || $class if ref $_[0] eq 'HASH';
    
    # Instantiate hash
    Carp::croak("Odd number arguments (${class}::new())") if @_ % 2;
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
            $code = sub {
                croak "${class}::$attr must be called from class."
                  if ref $_[0];
                
                my $class_attrs = do {
                    no strict 'refs';
                    ${"$_[0]::CLASS_ATTRS"} ||= {};
                };
                
                inherit_attribute($_[0], $attr, $options)
                  if @_ == 1 && ! exists $class_attrs->{$attr};
                
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $class_attrs->{$attr} = $_[1];
                    return $_[0];
                }
                
                return $class_attrs->{$attr};
            };
        }
        
        # With default option
        elsif (defined $default) {
            $code = sub {
                croak "${class}::$attr must be called from class."
                  if ref $_[0];

                my $class_attrs = do {
                    no strict 'refs';
                    ${"$_[0]::CLASS_ATTRS"} ||= {};
                };
                
                $class_attrs->{$attr} = ref $default ? $default->($_[0]) : $default
                  if @_ == 1 && ! exists $class_attrs->{$attr};
                
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $class_attrs->{$attr} = $_[1];
                    return $_[0];
                }
                
                return $class_attrs->{$attr};
            };
        }
        
        # Without option
        else {
            $code = sub {
                croak "${class}::$attr must be called from class."
                  if ref $_[0];

                my $class_attrs = do {
                    no strict 'refs';
                    ${"$_[0]::CLASS_ATTRS"} ||= {};
                };
                
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $class_attrs->{$attr} = $_[1];
                    return $_[0];
                }
                
                return $class_attrs->{$attr};
            };
        }
    }
    
    # Normal accessor
    else {
    
        # With inherit option
        if ($inherit) {
            $code = sub {
                inherit_attribute($_[0], $attr, $options)
                  if @_ == 1 && ! exists $_[0]->{$attr};
                
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $_[0]->{$attr} = $_[1];
                    return $_[0];
                }
                
                return $_[0]->{$attr};
            };            
        }
        
        # With default option
        elsif (defined $default) {
            $code = sub {
                $_[0]->{$attr} = ref $default ? $default->($_[0]) : $default
                  if @_ == 1 && ! exists $_[0]->{$attr};
                
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $_[0]->{$attr} = $_[1];
                    return $_[0];
                }
                return $_[0]->{$attr};
            };
        }
        
        # Without option
        else {
            $code = sub {
                if(@_ > 1) {
                    croak "Hash reference must be passed (${class}::$attr())" if @_ > 2;
                    $_[0]->{$attr} = $_[1];
                    return $_[0]
                }
                return $_[0]->{$attr};
            };
        }
    }
    
    return $code;
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

Object::Simple - Provide new() and accessor creating methods

=head1 STATE

This module is now stable. I will not change APIs and implemetations.
I will only fix bug if it is found.
Version 3.0601 implementation is keeped for ever.

=head1 VERSION

Version 3.0604

=cut

our $VERSION = '3.0604';

=head1 SYNOPSIS

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
    
    package main;
    
    use strict;
    use warnings;
    
    my $point = Point3D->new(x => 4, y => 6, z => 5);
    
    $point->x(1);
    $point->y(2);
    $point->z(5);
    
    my $x = $point->x;
    my $y = $point->y;
    my $z = $point->z;
    
    $point->clear;

=head1 FEATURES

This module has the folloing features. 

=over 4

=item 1. new() and accessor creating methods is prepared.

=item 2. Default value is available.

=item 3. Object Oriented interface and pure perl implemetation.

=item 4. Memory saving implementation and fast Compiling.

=item 5. Debugging is easy.

=back

You can think L<Object::Simple> is L<Class::Accessor::Fast> + "default value definition" + "useful new()"

This module's API is compatible of L<Mojo::Base>.
If you like L<Mojo::Base>, this module is good choice.

=head1 METHODS

=head2 new

A subclass of Object::Simple can call "new", and create a instance.
"new" receive hash or hash reference.

    package Point;
    use base 'Object::Simple';
    
    package main;
    my $book = Point->new;
    my $book = Point->new(x => 1, y => 2);
    my $book = Point->new({x => 1, y => 2});

"new" can be overrided to initialize the instance or arrange arguments.

Instance initialization

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

Arguments arranging
    
    sub new {
        my $self = shift;
        
        $self->SUPER::new(x => $_[0], y => $_[1]);
        
        return $self;
    }

=head2 attr

Create accessor.
    
    __PACKAGE__->attr('name');
    __PACKAGE__->attr([qw/name1 name2 name3/]);

A default value can be specified.
If dfault value is reference or object, You must wrap the value with sub { }.

    __PACKAGE__->attr(name => 'foo');
    __PACKAGE__->attr(name => sub { ... });
    __PACKAGE__->attr([qw/name1 name2/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2/] => sub { ... });

Accessor is chained.

    $point->x(3)->y(4);
    
The folloing is a sample.

    package Car;
    use base 'Object::Simple';
    
    __PACKAGE__->attr(maintainer => sub { ['Ken', 'Beck'] });
    __PACKAGE__->attr(handle => sub { Car::Handle->new });
    __PACKAGE__->attr([qw/speed passenger/] => 0);
    
=head2 class_attr

Create accessor for class attribute.

    __PACKAGE__->class_attr('name');
    __PACKAGE__->class_attr([qw/name1 name2 name3/]);
    __PACKAGE__->class_attr(name => 'foo');
    __PACKAGE__->class_attr(name => sub { ... });

This accessor is called from class.

    Book->title('BBB');

Class attribute is saved to $CLASS_ATTRS. This is class variable.
If you want to delete or check existence of a class attribute,
"delete" or "exists" function is available.

    delete $SomeClass::CLASS_ATTRS->{name};
    exists $SomeCLass::CLASS_ATTRS->{name};

If the class is a subclass, the class attribute is saved to $CLASS_ATTRS of subclass .
See the following sample.

    package Book;
    use base 'Object::Simple';
    
    __PACKAGE__->class_attr('title');
    
    package Magazine;
    use base 'Book';
    
    package main;
    
    Book->title('Beautiful days');
    Magazine->title('Good days');

If Book->title('Beautiful days') is called,
the value is saved to $Book::CLASS_ATTRS->{title}.
If Magazine->title('Good days') is called,
the value is saved to $Magazine::CLASS_ATTRS->{title}.

=head2 dual_attr

Create accessor for a attribute and class attribute.

    __PACKAGE__->dual_attr('name');
    __PACKAGE__->dual_attr([qw/name1 name2 name3/]);
    __PACKAGE__->dual_attr(name => 'foo');
    __PACKAGE__->dual_attr(name => sub { ... });

If the accessor is called from a package, the value is saved to $CLASS_ATTRS.
If the accessor is called from a instance, the value is saved to the instance.

    Book->title('Beautiful days');
    
    my $book = Book->new;
    $book->title('Good days');
    
=head1 OPTIONS
 
=head2 default
 
Define a default value.

    __PACKAGE__->attr('title', default => 'Good news');

If a default value is a reference or object,
You must wrap the value with sub { }.

    __PACKAGE__->attr('authors', default => sub{ ['Ken', 'Taro'] });
    __PACKAGE__->attr('ua',      default => sub { LWP::UserAgent->new });

Default value can be written by more simple way.

    __PACKAGE__->attr(title   => 'Good news');
    __PACKAGE__->attr(authors => sub { ['Ken', 'Taro'] });
    __PACKAGE__->attr(ua      => sub { LWP::UserAgent->new });

=head2 inherit

Inherit a attribute from a base class's one.

You can inherit a class attribute from base class's one.

    package BaseClass;
    use base 'Object::Simple';
    
    __PACKAGE__->class_attr('cache', default => 30, inherit => 'scalar_copy');
    
    package SomeClass;
    use base 'BaseClass';
    
    package main;
    my $obj = SomeClass->new;
    $obj->cache; # This is 30, which is inherited from BaseClass's cache.

inherit option must be 'scalar_copy', 'array_copy', 'hash_copy', or sub reference.
This is used to decide the way to copy the base class attribute.

The following is the implemetations to copy the value.

    'scalar copy' : Normal copy        : sub { return $_[0] }
    'array_copy'  : Array shallow copy : sub { return [@{$_[0]}] }
    'hash_copy'   : Hash shallow copy  : sub { return {%{$_[0]}} }
    sub reference : Your original copy : sub { ... }

If inherit option is specified at dual_attr(), a instance attribute inherit the class attribute.

    package SomeClass;
    use base 'Object::Simple';
    
    __PACKAGE__->dual_attr('filters',
        default => sub {
            {
                trim  => sub { ... },
                chomp => sub { ... }
            }
        },
        inherit => 'hash_copy'
    );
    
    package main;
    my $obj = SomeClass->new;
    $obj->filters; # This is { trim => sub { ... }, chomp => sub { ... } }
                   # , which is inherit from SomeClass's filters

Good example of inherit options is L<Validator::Custom::HTMLForm>.
See also this module.

=head1 PROVIDE ONLY ACCESSOR CREATING METHODS

If you want to provide only accessor creating methods, do the following way.

    package YourClass;
    use base 'LWP::UserAgent';
    
    use Object::Simple 'attr';
    
    __PACKAGE__->attr('foo');

=head1 SEE ALSO

L<Mojo::Base>, L<Class::Accessor::Fast>

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/Object-Simple>

=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

