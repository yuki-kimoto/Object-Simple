package M15_2;
use Object::Simple::Old;
use File::Basename 'fileparse';

sub m1 : Attr { default => 1 }

sub m3 : {
    my $self = shift;
    my $val  = shift;
    $val .= '/ccc';
    return fileparse($val);
}

Object::Simple::Old->build_class;
