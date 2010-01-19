package T29;
use Object::Simple::Old;


sub m1 : Attr {
    type => 'hash',
    default => sub{ { m1 => 1} },
    auto_build => sub{ $_[0]->m1(m1 => 2) },
    convert => 'T23',
    trigger => sub{
        if(ref $_[0]->m1 eq 'T23' && $_[0]->m1->m1 == 2){
           $_[0]->m2(3)
        }
    },
    chained => 1
}

sub m2 : Attr {}

Object::Simple::Old->build_class;
