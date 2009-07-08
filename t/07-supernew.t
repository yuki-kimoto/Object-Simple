use Test::More tests => 1;

use lib 't/07-supernew';

use PBook;

my $pbook = PBook->new( title => 'a', author => 'b' );

is_deeply( $pbook, { title => 'a', author => 'b' }, 'super class' );


