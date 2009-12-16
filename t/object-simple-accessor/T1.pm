package T1;
use Object::Simple;

use Object::Simple::Accessor qw/attr class_attr hybrid_attr/;

__PACKAGE__->attr('m1');
__PACKAGE__->class_attr('m2');
__PACKAGE__->hybrid_attr('m3');

__PACKAGE__->attr([qw/m4_1 m4_2/]);
__PACKAGE__->class_attr([qw/m5_1 m5_2/]);
__PACKAGE__->hybrid_attr([qw/m6_1 m6_2/]);


Object::Simple->build_class;
1;