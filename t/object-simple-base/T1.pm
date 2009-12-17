package T1;
use base 'Object::Simple::Base';

__PACKAGE__->attr('m1');
__PACKAGE__->class_attr('m2');
__PACKAGE__->hybrid_attr('m3');

__PACKAGE__->attr([qw/m4_1 m4_2/]);
__PACKAGE__->class_attr([qw/m5_1 m5_2/]);
__PACKAGE__->hybrid_attr([qw/m6_1 m6_2/]);

__PACKAGE__->attr(m7 => (build => 7));
__PACKAGE__->attr([qw/m8_1 m8_2/] => (build => sub { 8 }));

__PACKAGE__->class_attr(m9 => (build => 9));
__PACKAGE__->hybrid_attr(m10 => (build => 10));

__PACKAGE__->attr(m11 => (type => 'array', deref => 1));
__PACKAGE__->attr(m12 => (type => 'hash', deref => 1));

__PACKAGE__->class_attr(m13 => (type => 'array', deref => 1));
__PACKAGE__->class_attr(m14 => (type => 'hash', deref => 1));

__PACKAGE__->hybrid_attr(m15 => (type => 'array', deref => 1));
__PACKAGE__->hybrid_attr(m16 => (type => 'hash', deref => 1));

__PACKAGE__->hybrid_attr(m17 =>
    type => 'hash', build => sub {{a => 1}}, clone => 'hash');


package T1_2;
use base 'T1';


package T1_3;
use base 'T1_2';



1;
