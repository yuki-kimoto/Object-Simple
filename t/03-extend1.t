use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/03-extend1';

use Book;
use PBook;

use strict;
use warnings;

my $book = Book->new;
my $pbook = PBook->new;

$book->title;
is( $pbook->title, 1, 'method invoked atfter super class dose' );

{
    use T2;
    my $t = T2->new;
    is_deeply($t, {m1 => 1, m2 => 2, title => 1}, 'use base');
    
}

{
    use T3;
    my $t = T3->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, title => 1}, 'use base');
}




__END__