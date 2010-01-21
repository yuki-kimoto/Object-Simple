package T1;
use base 'Object::Simple::Base';

use strict;
use warnings;

use Object::Simple::Util;


__PACKAGE__->attr('m1');
__PACKAGE__->class_attr('m2');
__PACKAGE__->dual_attr('m3');

__PACKAGE__->attr([qw/m4_1 m4_2/]);
__PACKAGE__->class_attr([qw/m5_1 m5_2/]);
__PACKAGE__->dual_attr([qw/m6_1 m6_2/]);

__PACKAGE__->attr('m7', default => 7);
__PACKAGE__->attr([qw/m8_1 m8_2/], default => sub { 8 });

__PACKAGE__->class_attr('m9', default => 9)
           ->dual_attr('m10', default => 10);


__PACKAGE__->dual_attr('m17', default => sub { {a => 1} }, inherit => 'hash');


package T1_2;
use base 'T1';

package T1_3;
use base 'T1_2';



1;
