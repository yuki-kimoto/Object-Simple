use Test::More  'no_plan';

use lib 't/08-import-error';

eval "use MyTest1";
like( $@, qr/constrain of MyTest1::p must be code ref/,
         'constrain non sub ref' );

eval "use T4";
like( $@, qr/'build_a3' must exist in 'T4' when 'auto_build' option is set/, 'no build method' );

eval "use T8";
like( $@, qr/T8::a4 'retval' option must be 'undef', 'old', 'current', or 'self'\./, 'setter return value no_exist option' );
