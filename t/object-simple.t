use Test::More 'no_plan';
use strict;
use warnings;

eval "use Object::Simple";
like($@, qr/\QCannot use 'Object::Simple'. This is just a name space/, "Cannot use 'Object::Simple'");

