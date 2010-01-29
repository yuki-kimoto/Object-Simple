package Object::Simple;
use strict;
use warnings;
use Carp ();

my %EXPORTS = map { $_ => 1 } qw/new attr class_attr dual_attr/;

sub import {
    my ($self, @methods) = @_;
    
    # Caller
    my $caller = caller;
    
    # Export methods
    foreach my $method (@methods) {
        
        # Can be Exported?
        Carp::croak("Cannot export '$method'.")
          unless $EXPORTS{$method};
        
        # Export
        no strict 'refs';
        *{"${caller}::$method"} = \&{"$method"};
    }
}

sub new {
    my $class = shift;

    # Instantiate
    return bless
      exists $_[0] ? exists $_[1] ? {@_} : {%{$_[0]}} : {},
      ref $class || $class;
}

my $Util = 'Object::Simple::Util';

sub attr       { $Util->create_accessors(shift, 'attr',       @_) }
sub class_attr { $Util->create_accessors(shift, 'class_attr', @_) }
sub dual_attr  { $Util->create_accessors(shift, 'dual_attr',  @_) }


package Object::Simple::Util;

use strict;
use warnings;
use Carp 'croak';

sub create_accessors {
    my ($self, $class, $type, $attrs, @options) = @_;
    
    # To array
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Arrange options
    my $options = @options > 1 ? {@options} : {default => $options[0]};
    
    # Check options
    foreach my $oname (keys %$options) {
        my $is_valid = 1;
        
        if ($type eq 'attr') {
            $is_valid = 0 unless $oname eq 'default'
        }
        else {
            $is_valid = 0 unless $oname eq 'default' || $oname eq 'inherit';
        }
        croak "'$oname' is invalid option" unless $is_valid;
    }
    
    # Create accessors
    foreach my $attr (@$attrs) {
        
        # Create accessor
        my $code = $type eq 'attr'
                 ? $self->create_accessor($class, $attr, $options)
                 
                 : $type eq 'class_attr'
                 ? $self->create_class_accessor($class, $attr, $options)
                 
                 : $type eq 'dual_attr'
                 ? $self->create_dual_accessor($class, $attr, $options)
                 
                 : undef;
        
        # Import
        no strict 'refs';
        *{"${class}::$attr"} = $code;
    }
}

sub create_accessor {
    my ($self, $class, $attr, $options, $attr_type) = @_;
    
    # Attribute type
    $attr_type ||= '';
    
    # Options
    my $default = $options->{default};
    my $inherit = $options->{inherit};
    
    # Beginning of accessor
    my $src =  qq/sub {\n/;
    
    # Strage
    my $strage;
    if ($attr_type eq 'class') {
        
        # Initialize class variables
        {
            no strict 'refs';
            ${"${class}::CLASS_ATTRS"} ||= {};
        }
        
        # Class variable
        $strage = "\$${class}::CLASS_ATTRS->{'$attr'}";
        
        # Called from a instance
        $src .= qq/    Carp::croak("${class}::$attr must be called / .
                qq/from a class, not a instance")\n/ .
                qq/      if ref \$_[0];\n/;
    }
    else {
        # Instance variable
        $strage = "\$_[0]->{'$attr'}";
    }
    
    # Check default option
    croak "'default' option must be scalar or code ref (${class}::$attr)"
      unless !ref $default || ref $default eq 'CODE';
    
    # Inherit
    if ($inherit) {
        # Check 'inherit' option
        croak("'inherit' opiton must be 'scalar_copy', 'array_copy', " . 
              "'hash_copy', or code reference (${class}::$attr)")
          unless $inherit eq 'scalar_copy' || $inherit eq 'array_copy'
              || $inherit eq 'hash_copy'   || ref $inherit eq 'CODE';
        
        # Inherit code
        $src .= qq/    if(\@_ == 1 && ! exists $strage) {\n/ .
                qq/        Object::Simple::Util->inherit_prototype(\n/ .
                qq/            \$_[0],\n/ .
                qq/            '$attr',\n/ .
                qq/            \$options\n/ .
                qq/        );\n/ .
                qq/    }\n/;
    }
    
    # Default
    elsif ($default) {
        $src .= qq/    if(\@_ == 1 && ! exists $strage) {\n/ .
                qq/        \$_[0]->$attr(\n/;
            
        $src .= ref $default
              ? qq/            \$options->{default}->(\$_[0])\n/
              : qq/            \$options->{default}\n/;
        
        $src .= qq/        )\n/ .
                qq/    }\n/;
    }
    
    # Set and get
    $src .=     qq/    if(\@_ > 1) {\n/ .
                qq/        $strage = \$_[1];\n/ .
                qq/        return \$_[0]\n/ .
                qq/    }\n/ .
                qq/    return $strage;\n/;
    
    # End of accessor source code
    $src .=     qq/}\n/;
    
    # Code
    my $code = eval $src;
    croak("$src\n:$@") if $@;
                
    return $code;
}

sub create_class_accessor  { shift->create_accessor(@_[0 .. 2], 'class') }

sub create_dual_accessor {
    my ($self, $class, $accessor_name, $options) = @_;
    
    # Create accessor
    my $accessor = $self->create_accessor($class, $accessor_name, $options);
    
    # Create class accessor
    my $class_accessor
      = $self->create_class_accessor($class, $accessor_name, $options);
    
    # Create dual accessor
    my $code = sub {
        my $invocant = shift;
        return ref $invocant ? $accessor->($invocant, @_)
                             : $class_accessor->($invocant, @_);
    };
    
    return $code;
}

sub inherit_prototype {
    my $self          = shift;
    my $invocant      = shift;
    my $accessor_name = shift;
    my $options = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    
    # Inherit option
    my $inherit   = $options->{inherit};
    
    # Check inherit option
    unless (ref $inherit eq 'CODE') {
        if ($inherit eq 'scalar_copy') {
            $inherit = sub { $_[0] };
        }
        elsif ($inherit eq 'array_copy') {
            $inherit = sub { return [@{$_[0]}] };
        }
        elsif ($inherit eq 'hash_copy') {
            $inherit = sub { return { %{$_[0]} } };
        }
    }
    
    # Default options
    my $default = $options->{default};
    
    # Get default value from sub reference
    $default = $default->() if ref $default eq 'CODE';
    
    # Called from a object
    if (my $class = ref $invocant) {
        $invocant->$accessor_name($inherit->($class->$accessor_name));
    }
    
    # Called from a class
    else {
        my $super =  do {
            no strict 'refs';
            ${"${invocant}::ISA"}[0];
        };
        my $value = eval{$super->can($accessor_name)}
                       ? $inherit->($super->$accessor_name)
                       : $default;
                          
        $invocant->$accessor_name($value);
    }
}

package Object::Simple;

=head1 NAME

Object::Simple - a base class to provide constructor and accessors

=head1 VERSION

Version 3.0301

=cut

our $VERSION = '3.0301';

=head1 SYNOPSIS
    
    package Book;
    use base 'Object::Simple';
    
    __PACKAGE__->attr('title');
    __PACKAGE__->attr(pages => 159);
    __PACKAGE__->attr([qw/authors categories/] => sub { [] });
    
    __PACKAGE__->class_attr('foo');
    __PACKAGE__->class_attr(foo => 1);
    __PACAKGE__->class_attr('foo', default => 1, inherit => 'scalar_copy');
    
    __PACKAGE__->dual_attr('bar');
    __PACAKGE__->dual_attr(bar => 2);
    __PACAKGE__->dual_attr('bar', default => 1, inherit => 'scalar_copy');
    
    package main;
    use Book;
 
    my $book = Book->new;
    print $book->pages;
    print $book->pages(5)->pages;
 
    my $my_book = Car->new(title => 'Good Day');
    print $book->authors(['Ken', 'Tom'])->authors;
    
    Book->foo('a');
    
    Book->bar('b');
    $book->bar('c');

=head1 Methods

=head2 new

A subclass of Object::Simple can call "new", and create a instance.
"new" can receive hash or hash ref.

    package Book;
    use base 'Object::Simple';
    
    package main;
    my $book = Book->new;
    my $book = Book->new(title => 'Good day');
    my $book = Book->new({title => 'Good'});

"new" can be overrided to arrange arguments or initialize the instance.

Arguments arrange
    
    sub new {
        my ($class, $title, $author) = @_;
        
        my $self = $class->SUPER::new(title => $title, author => $author);
        
        return $self;
    }

Instance initialization

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

=head2 attr

Create accessor.
    
    __PACKAGE__->attr('name');
    __PACKAGE__->attr([qw/name1 name2 name3/]);

A default value can be specified.
If array ref, hash ref, or object is specified as a default value,
that must be wrapped with sub { }.

    __PACKAGE__->attr(name => 'foo');
    __PACKAGE__->attr(name => sub { ... });
    __PACKAGE__->attr([qw/name1 name2/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2/] => sub { ... });

Options can be specified.

    __PACKAGE__->attr('name', default => sub {[]}, inherit => 'hash_copy');

=head2 class_attr

Create accessor for class variable.

    __PACKAGE__->class_attr('name');
    __PACKAGE__->class_attr([qw/name1 name2 name3/]);
    __PACKAGE__->class_attr(name => 'foo');
    __PACKAGE__->class_attr(name => sub { ... });

This accessor is called from package, not instance.

    Book->title('BBB');

Class variables is saved to package variable "$CLASS_ATTRS". If you want to
delete the value or check existence, "delete" or "exists" function is available.

    delete $Book::CLASS_ATTRS->{title};
    exists $Book::CLASS_ATTRS->{title};

If This class is inherited, the value is saved to package variable of subclass.
For example, Book->title('Beautiful days') is saved to $Book::CLASS_ATTRS->{title},
and Magazine->title('Good days') is saved to $Magazine::CLASS_ATTRS->{title}.

    package Book;
    use base 'Object::Simple';
    
    __PACKAGE__->class_attr('title');
    
    package Magazine;
    use base 'Book';
    
    package main;
    
    Book->title('Beautiful days'); # Saved to $Book::CLASS_ATTRS->{title}
    Magazine->title('Good days');  # Saved to $Magazine::CLASS_ATTRS->{title}

=head2 dual_attr

Create accessor for a instance and class variable.

    __PACKAGE__->dual_attr('name');
    __PACKAGE__->dual_attr([qw/name1 name2 name3/]);
    __PACKAGE__->dual_attr(name => 'foo');
    __PACKAGE__->dual_attr(name => sub { ... });

If this accessor is called from a package, the value is saved to $CLASS_ATTRS.
If this accessor is called from a instance, the value is saved to the instance.

    Book->title('Beautiful days'); # Saved to $CLASS_ATTRS->{title};
    
    my $book = Book->new;
    $book->title('Good days'); # Saved to $book->{title};
    
=head1 Options
 
=head2 default
 
Define a default value.

    __PACKAGE__->attr('title', default => 'Good news');

If a default value is array ref, or hash ref, or object,
the value is wrapped with sub { }.

    __PACKAGE__->attr('authors', default => sub{ ['Ken', 'Taro'] });
    __PACKAGE__->attr('ua',      default => sub { LWP::UserAgent->new });

Default value can be written by more simple way.

    __PACKAGE__->attr(title   => 'Good news');
    __PACKAGE__->attr(authors => sub { ['Ken', 'Taro'] });
    __PACKAGE__->attr(ua      => sub { LWP::UserAgent->new });


=head2 inherit

Package variable of super class is copied to the class at first access, If the accessor is for class.
Package variable is copied to the instance, If the accessor is for instance.

"inherit" is available by "class_attr", and "dual_attr".
This options is generally used with "default" value.

    __PACKAGE__->dual_attr('contraints', default => sub { {} }, inherit => 'hash_copy');
    
"scalar_copy", "array_copy", "hash_copy" is specified as "inherit" options.

Any subroutine for inherit is also available.

    __PACKAGE__->dual_attr('url', default => sub { URI->new }, 
                                  inherit   => sub { shift->clone });

=head1 Prototype system

L<Object::Simple> provide a prototype system like JavaScript.

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
    
This prototype system is very useful to create castamizable class for user.

This prototype system is used in L<Validator::Custom> and L<DBIx::Custom>.

See L<Validator::Custom> and L<DBIx::Custom>.

=head1 Provide only a ability to create accessor to a class.

If you want to provide only a ability to create accessor a class, do this.

    package YourClass;
    use base 'LWP::UserAgent';
    
    use Object::Simple 'attr';
    
    __PACKAGE__->attr('foo');

=head1 Similar module

This module is compatible with L<Mojo::Base>.

If you like L<Mojo::Base>, L<Object:Simple> is good select for you.

=head1 Author
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/Object-Simple>

Please tell me bug if you find.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

