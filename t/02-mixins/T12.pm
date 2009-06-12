package T12;
use Object::Simple( base => 'B2', mixins => ['M8', 'M9'], mixins_rename => []);

Object::Simple->build_class;
