use strict;
use warnings;
use Test::More tests => 1;

use lib 't/05-extend3';

use Book;
use PBook;

use strict;
use warnings;

my $book = Book->new;
my $pbook = PBook->new;

$pbook->title;
is( $pbook->title, 1, 'method invoked atfter super class dose' );





__END__