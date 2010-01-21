package Object::Simple;
use strict;
use warnings;
use Carp 'croak';

sub import { croak "Cannot use 'Object::Simple'. This is just a name space" }

=head1 NAME
 
Object::Simple - Simple OO framework
 
=head1 VERSION

Version 3.0101

=cut

our $VERSION = '3.0101';

=head1 SYNOPSIS
    
    package Book;
    use base 'Object::Simple::Base';
 
    __PACKAGE__->attr('title');
    __PACKAGE__->attr(pages => 159);
    __PACKAGE__->attr([qw/authors categories/] => sub { [] });
    
    __PACKAGE__->class_attr('foo');
    __PACKAGE__->class_attr(foo => 1);
    __PACAKGE__->class_attr('foo', default => 1, inherit => 'scalar');
    
    __PACKAGE__->dual_attr('bar');
    __PACAKGE__->dual_attr(bar => 2);
    __PACAKGE__->dual_attr('bar', default => 1, inherit => 'scalar');
    
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

=head1 DESCRIPTION

Object::Simple is a simple OO framework.

By using Object::Simple, you will be exempt from the bitter work of
repeatedly writing the new() constructor and the accessors.

L<Object::Simple> contains three classes.
L<Object::Simple::Base>, L<Object::Simple::Accessor>
L<Object::Simple> itself is just a name space.

L<Object::Simple::Base> is a base class of a class.
It provides new(), which is a constructor,
and attr(), class_attr(), dual_attr(), which is the methods to create a accessor.

L<Object::Simple::Base> is compatible of L<Mojo::Base>. If you like L<Mojo:Base>,
L<Object::Simple::Base> is a good select.

L<Object::Simple::Accessor> provides accessor creating methods(attr(), class_attr(), dual_attr()) to L<Mojo::Base>.
This is useful to provide only a accessor creating ability to your class.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1; # End of Object::Simple

