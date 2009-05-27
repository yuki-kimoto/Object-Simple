use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/06-extend-multi';

eval "use Book3";
like( $@, qr/Invalid class name/ );
