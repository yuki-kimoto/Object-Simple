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
    my $t = T3->new(m4 => 4);
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3, m4 => 4, title => 1}, 'use base');
    
    ok($Object::Simple::META->{T3}{constructor}, 'cache constructor');
    my $t2 = T3->new(m4 => 4);
    is_deeply($t2, {m1 => 1, m2 => 2, m3 => 3, m4 => 4, title => 1}, 'use base');
}

{
    use T4;
    my $t = T4->new;
    is_deeply($t, {m1 => 1, m2 => 2, m3 => 3}, 'inheritance');
}



__END__