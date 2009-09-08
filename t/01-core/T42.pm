package T42_Base_1;
use Object::Simple;

sub m1 : Attr : { default => sub { {a => 1} }, type => 'hash', deref => 1 }
sub m2 : Attr : { default => sub { {c => 1} }, type => 'array', deref => 1 }


Object::Simple->build_class;


package T42_Base_2;
use Object::Simple(base => 'T42_Base_1');

sub m2 : Attr : { extend => 1, type => 'hash', deref => 1 }

Object::Simple->build_class;


package T42;
use Object::Simple(base => 'T42_Base_2');

sub m1 : Attr : { extend => 1, default => sub { {b => 2} } }
sub m2 : Attr : { extend => 1 }

Object::Simple->build_class;


