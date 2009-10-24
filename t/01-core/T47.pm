# undef value set
package T47;
use Object::Simple;

sub m1 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm1',
        clone         => 'scalar',
        default       => 1
    })
}}

sub m2 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm2',
        clone         => 'array',
        default       => sub {['1', '2']}
    })
}}

sub m3 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm3',
        clone         => 'hash',
        default       => sub {{a => 1, b => 2}}
    })
}}

sub m4 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm4',
        clone         => sub { $_[0] * 2 },
        default       => sub {3}
    })
}}

sub m5 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm5',
        clone         => 'noexist',
        default       => sub {3}
    })
}}

sub m6 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        clone         => 'scalar',
        default       => sub {3}
    })
}}

sub m7 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm7',
        clone         => 'scalar',
        default       => []
    })
}}

sub m8 : ClassObjectAttr {auto_build => sub {
    shift->Object::Simple::initialize_class_object_attr({
        accessor_name => 'm8',
        clone         => 'scalar',
    })
}}

Object::Simple->build_class;

package T47_2;
use base 'T47';

package T47_3;
use base 'T47_2';

package T47_4;
use base 'T47_3';





1;