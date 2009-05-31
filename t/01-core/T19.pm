package T19;
use Object::Simple;

sub m1 : Attr {}

no Object::Simple;

our $OK;

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $ref, @attrs) = @_;
    if($attrs[0] eq 'X') {
        $OK = 1;
    }
    return;
}

sub m2 : X {}

Object::Simple->end;
