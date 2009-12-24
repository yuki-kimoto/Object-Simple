package Object::Simple::Base;
use strict;
use warnings;

use Object::Simple::Accessor qw/attr class_attr hybrid_attr/;

use base 'Exporter';
our @EXPORT_OK = ('new');

sub new {
    my $class = shift;

    # Instantiate
    return bless
      exists $_[0] ? exists $_[1] ? {@_} : {%{$_[0]}} : {},
      ref $class || $class;
}

=head1 NAME

Object::Simple::Base - a base class to provide constructor and accessors

=head1 SYNOPSIS
    
    package Book;
    use base 'Object::Simple::Base';
 
    __PACKAGE__->attr('title');
    __PACKAGE__->attr('pages' => 159);
    __PACKAGE__->attr([qw/authors categories/] => sub { [] });
    
    __PACKAGE__->class_attr('aaa');
    __PACKAGE__->hybrid_attr('bbb');
 
    package main;
    use Book;
 
    my $book = Book->new;
    print $book->pages;
    print $book->pages(5)->pages;
 
    my $my_book = Car->new(title => 'Good Day');
    print $book->authors(['Ken', 'Tom'])->authors;

=head1 Methods

=head2 new

Create instance.

    my $instance = Book->new;
    my $instance = Book->new(title => 'Good day');
    my $instance = Book->new({name => 'Good'});

'new' can be overrided to arrange arguments or initialize instance.

Arrange arguments :
    
    sub new {
        my ($class, $title, $author) = @_;
        
        # Arrange arguments
        my $self = $class->SUPER::new(title => $title, author => $author);
        
        return $self;
    }

Initialize:

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialize instance
        
        return $self;
    }

If you use one of 'weak', 'convert', or 'trigger' options,
It will be better to initialize attributes.

    __PACKAGE__->attr(parent => (weak => 1));
    __PACAKGE__->attr(params => (convert => 'Parameters'));
    
    sub new {
        my $self = shift->SUPER::new(@_);
        
        foreach my $attr (qw/parent params/) {
            $self->$attr($self->{$attr}) if exists $self->{$attr};
        }
        
        return $self;
    }

This is a little bitter work. Object::Simple::Util 'init_attrs' method is useful.
    
    use Object::Simple::Util;
    sub new {
        my $self = shift->SUPER::new(@_);
        
        Object::Simple::Util->init_attrs($self, qw/parent params/);
        
        return $self;
    }

=head2 attr

Create a accessor

    __PACKAGE__->attr('name');

Create accessors

    __PACKAGE__->attr([qw/name1 name2 name3/]);

Create a accessor specifying a default value.

    __PACKAGE__->attr(name => 'foo');       # string or number
    __PACKAGE__->attr(name => sub { ... }); # reference or object

Create accessors specifying a default value.

    __PACKAGE__->attr([qw/name1 name2/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2/] => sub { ... });

Create a accessor specifying options

    __PACKAGE__->attr(name => (default => sub {[]}, type => 'array', deref => 1));


=head2 class_attr

Create accessor for class variable

    __PACKAGE__->class_attr('name');
    __PACKAGE__->class_attr([qw/name1 name2 name3/]);

Create a accessor specifying a default value.

    __PACKAGE__->class_attr(name => 'foo');
    __PACKAGE__->class_attr(name => sub { ... });

'clone' options is available for 'class_attr'.

    __PACKAGE__->class_attr(name => (default => sub {[]}, clone => 'array'));

Class variables is saved to $CLASS_ATTRS package variable. If you want to
delete the value, 'delete' function is available.

    delete $CLASS_ATTRS->{title};

=head2 hybrid_attr

Create a accessor for both attribute and class variable

    __PACKAGE__->hybrid_attr('name');
    __PACKAGE__->hybrid_attr([qw/name1 name2 name3/]);

Create a accessor specifying a default value.

    __PACKAGE__->hybrid_attr(name => 'foo');
    __PACKAGE__->hybrid_attr(name => sub { ... });

'clone' options is available for 'hybrid_attr'.

    __PACKAGE__->hybrid_attr(name => (default => sub {[]}, clone => 'array'));


=head1 Accessor options
 
=head2 default
 
Define a default value.

    __PACKAGE__->attr(title => (default => 'Good news'));

In case, array ref, or hash ref, or object.

    __PACKAGE__->attr(authors => (default => sub{ ['Ken', 'Taro'] }));
    __PACKAGE__->attr(ua      => (default => sub { LWP::UserAgent->new }));

Shortcut

    __PACKAGE__->attr(title   => 'Good news');
    __PACKAGE__->attr(authors => sub { ['Ken', 'Taro'] });
    __PACKAGE__->attr(ua      => sub { LWP::UserAgent->new });

=head2 weak

Weaken a reference.
 
    __PACKAGE__->attr(parent => (weak => 1));

=head2 type

Specify a variable type.

    sub authors    : Attr { type => 'array' }
    sub country_id : Attr { type => 'hash' }

'array' convert list values to a array ref

     $book->authors('ken', 'taro'); # ('ken', 'taro') -> ['ken', 'taro']
     $book->authors('ken');         # ('ken')         -> ['ken']

'hash' convert list values to a hash ref.

     $book->country_id(Japan => 1); # (Japan => 1)    -> {Japan => 1}

=head2 deref

Dereffernce a array ref or hash ref.

reference

You can derefference returned value.You must specify it with 'type' option.
    
    sub authors : Attr { type => 'array', deref => 1 }
    sub country_id : Attr { type => 'hash',  deref => 1 }

    my @authors = $book->authors;
    my %country_id = $book->country_id;

=head2 convert

You can convert a non blessed scalar value to object.

    sub url : Attr { convert => 'URI' }
    
    $book->url('http://somehost'); # convert to URI->new('http://somehost')

You can also convert a scalar value using your convert function.

    sub url : Attr { convert => sub{ ref $_[0] ? $_[0] : URI->new($_[0]) } }

    
=head2 trigger

You can defined trigger function when value is set.

    sub error : Attr { trigger => sub{
        my ($self, $old) = @_;
        $self->state('error') if $self->error;
    }}
    sub state : Attr {}

trigger function recieve two argument.

    1. $self
    2. $old : old value

=head2 clone

Clone prototype.

'clone' option is available by 'class_attr', and 'hybrid_attr';

    __PACKAGE__->hybrid_attr(contraints => (clone => 'hash', default => sub { {} }));
    
You can specify the way of copy. 'scalar', 'array', 'hash' is available.

You can also your clone method.

    clone => sub { shift->clone }

=head1 Prototype system

L<Object::Simple::Base> provide a prototype system like JavaScript.

+--------+ 
| Class1 |
+--------+ 
    |
    v
+--------+    +-----------+
| Class2 | -> |instance 2 |
+--------+    +-----------+


'Class1' has 'title' accessor using 'hybrid_attr' and 'clone' option.

    package Class1;
    use base 'Object::Simple::Base';
    
    __PACKAGE__->hybrid_attr(title => (default => 'Good day', clone => 'scalar'));

You can set 'title' value in a subclass.

    package Class2;
    use base Class2;
    
    __PACKAGE__->title('Better day');
    
This value is used when instance is created.

    package main;
    my $book = Class2->new;
    $book->title; # 'Better day'

This prototype system is used in L<Validator::Custom> and L<DBIx::Custom>.

=head1 Export

Can import 'new' method to your package.

    package YourClass;
    use Object::Simple::Base 'new';


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

