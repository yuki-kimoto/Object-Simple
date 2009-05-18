package T8;
use Object::Simple;

sub a4 : Attr { default => 1, retval => 'no_exist' }
Object::Simple->end;

