package M16;
use Object::Simple;
use File::Basename 'basename';

sub m2 : Attr { default => 2 }

sub m3 {
    my $self = shift;
    my $file = basename('aaa/bbb');
    return $self->SUPER::m3($file);
}

sub m4 {
    return 4;
}

Object::Simple->build_class;
