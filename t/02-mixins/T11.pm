package T11;
use Object::Simple( base => 'B2', mixins => ['M8', 'M9'], mixins_rename => {'M8::m4' => 'r4', 'M9::m5' => 'r5' });

sub m1 : Attr { default => 1 }


Object::Simple->end;
