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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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
                    croak "Too many arguments (${class}::$attr())" if @_ > 2;
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

Object::Simple - Provide new() and accessor creating abilities

=head1 STATE

This module is not stable. API will be changed for a while.

=head1 VERSION

Version 3.0601

=cut

our $VERSION = '3.0601';

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

=item 1. new() is prepared. You do not have to define new().

=item 2. Provide accessor creating abilities.

=item 3. Default value is available.

=item 4. Object Oriented interface.

=item 5. Memory saving implementation.

=item 6. Fast Compiling.

=item 7. Fast new() and accessors as possible.

=item 8. Pure perl and one file.

=item 9. Debugging is easy.

=item 10. Provide class accessor creating ability

=item 11. Probide class attribute inheriting system.

=back

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

"new" can be overrided to arrange arguments or initialize the instance.

Instance initialization

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

Arguments arranging
    
    sub new { shift->SUPER::new(x => $_[0], y => $_[1]) }

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

If the accessor is for class class variable, 
Package variable of super class is copied to the class at first access,
If the accessor is for instance, Package variable is copied to the instance, .

"inherit" is available by "class_attr", and "dual_attr".
This options is generally used with "default" value.

    __PACKAGE__->dual_attr('contraints', default => sub { {} }, inherit => 'hash_copy');
    
"scalar_copy", "array_copy", "hash_copy" is specified as "inherit" options.
scalar_copy is normal copy. array_copy is [@{$array}], hash_copy is [%{$hash}].

Your subroutine is also available to copy the value.

    __PACKAGE__->dual_attr('url', default => sub { URI->new }, 
                                  inherit => sub { shift->clone });
 
L<Object::Simple> provide class attribute inhertance system.

    +--------+ 
    | Class1 |
    +--------+ 
        |
        v
    +--------+    +----------+
    | Class2 | -> |instance2 |
    +--------+    +----------+

"Class1" has "title" accessor using "dual_attr" with "inherit" options.

    package Class1;
    use base 'Object::Simple';
    
    __PACKAGE__->dual_attr('title', default => 'Good day', inherit => 'scalar_copy');

"title" can be changed in "Class2".

    package Class2;
    use base Class1;
    
    __PACKAGE__->title('Beautiful day');
    
This value is used when instance is created. "title" value is "Beautiful day"

    package main;
    my $book = Class2->new;
    $book->title;
    
This prototype system is useful to create castamizable class.

See L<Validator::Custom> and L<DBIx::Custom>.

=head1 PROVIDE ONLY ACCESSOR CREATING ABILITIES

If you want to provide only a ability to create accessor a class, do the following way.

    package YourClass;
    use base 'LWP::UserAgent';
    
    use Object::Simple 'attr';
    
    __PACKAGE__->attr('foo');

=head1 SEE ALSO

This module is compatible with L<Mojo::Base>.

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/Object-Simple>

Please tell me bug if you find.

=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

