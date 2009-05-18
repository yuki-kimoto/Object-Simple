use strict;
use warnings;

use Test::More tests => 1;

package Book;
use Simo;
sub new{ bless { k => 1 }, __PACKAGE__ }

package PBook; use base 'Book';
use Simo;

package main;
my $pbook = PBook->new;
is_deeply( $pbook, { k => 1 }, 'inherit super class and call new' );
