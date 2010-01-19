package T19;
use Object::Simple::Old;

sub m1 : Attr {}

no Object::Simple::Old;

our $OK;

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $ref, @attrs) = @_;
    if($attrs[0] eq 'X') {
        $OK = 1;
    }
    return;
}

sub m2 : X {}

Object::Simple::Old->build_class;
