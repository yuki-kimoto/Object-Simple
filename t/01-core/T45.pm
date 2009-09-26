package T45;
use Object::Simple(base => 'T45_Base', mixins => [qw/T45_Mixin T45_Mixin2/]);

Object::Simple->build_class;


