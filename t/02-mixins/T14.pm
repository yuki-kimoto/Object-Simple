package T14;
use Object::Simple( base => 'B2', mixins => ['M8', 'M9'], mixins_rename => {'M8::m4' => '^^^'});

sub m1 : Attr { default => 1 }
sub m2 : Attr { default => 2 }
sub m3 : Attr { default => 5 }



Object::Simple->end;
