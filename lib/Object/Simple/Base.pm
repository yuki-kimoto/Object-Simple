package Object::Simple::Base;
use strict;
use warnings;

use Object::Simple::Accessor qw/attr class_attr hybrid_attr/;

use base 'Exporter';
our @EXPORT_OK = qw/new to_string/;

sub new {
    my $class = shift;

    # Instantiate
    return bless
      exists $_[0] ? exists $_[1] ? {@_} : {%{$_[0]}} : {},
      ref $class || $class;
}

=head1 NAME

Object::Simple::Base - Provide constructor and accessors

=head1 SYNOPSIS
    
    package Book;
    use base 'Object::Simple::Base';
 
    __PACKAGE__->attr('title');
    __PACKAGE__->attr('pages' => 159);
    __PACKAGE__->attr([qw/authors categories/] => sub { [] });
 
    package main;
    use Book;
 
    my $book = Book->new;
    print $book->pages;
    print $book->pages(5)->pages;
 
    my $my_book = Car->new(title => 'Good Day');
    print $book->authors(['Ken', 'Tom'])->authors;

=head1 Methods

=head2 new

    my $instance = BaseSubClass->new;
    my $instance = BaseSubClass->new(name => 'value');
    my $instance = BaseSubClass->new({name => 'value'});

=head2 attr

Create accessor

    __PACKAGE__->attr('name');
    __PACKAGE__->attr([qw/name1 name2 name3/]);
    __PACKAGE__->attr(name => 'foo');
    __PACKAGE__->attr(name => sub { ... });
    __PACKAGE__->attr([qw/name1 name2 name3/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2 name3/] => sub { ... });

You can use some options provided by L<Object::Simple>

    1. build
    2. type
    3. deref

Create accessor specifying options

    __PACKAGE__->attr(name => (build => sub {[]}, type => 'array', deref => 1));

=head2 class_attr

Create accessor for class variable

Usage is almost same as 'attr'

Special option 'clone' is available for 'class_attr'.

    __PACKAGE__->class_attr(name => (build => sub {[]}, clone => 'array'));

See L<Object::Simple> about 'clone' option.

=head2 hybrid_attr

Create accessor for both attribute and class variable

Usage is same as 'class_attr'

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

