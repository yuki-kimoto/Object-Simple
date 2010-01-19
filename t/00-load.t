#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Object::Simple::Base' );
}
diag( "Testing Object::Simple $Object::Simple::VERSION, Perl $], $^X" );
