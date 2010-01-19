package T1;
use base 'Object::Simple::Base';

use strict;
use warnings;

use Object::Simple::Util;

my $p= __PACKAGE__;

$p->attr('m1')
  ->class_attr('m2')
  ->dual_attr('m3')

  ->attr([qw/m4_1 m4_2/])
  ->class_attr([qw/m5_1 m5_2/])
  ->dual_attr([qw/m6_1 m6_2/])

  ->attr(m7 => (build => 7))
  ->attr([qw/m8_1 m8_2/] => (default => sub { 8 }))

  ->class_attr(m9 => (default => 9))
  ->dual_attr(m10 => (default => 10))

  ->attr(m11 => (type => 'array', deref => 1))
  ->attr(m12 => (type => 'hash', deref => 1))

  ->class_attr(m13 => (type => 'array', deref => 1))
  ->class_attr(m14 => (type => 'hash', deref => 1))

  ->dual_attr(m15 => (type => 'array', deref => 1))
  ->dual_attr(m16 => (type => 'hash', deref => 1))

  ->dual_attr(m17 =>
      type => 'hash', default => sub {{a => 1}}, clone => 'hash')
;

$p->attr('m18' => (trigger => sub { shift->m19(2) }))
  ->attr('m19')
;

sub new {
    my $self = shift->SUPER::new(@_);
    
    Object::Simple::Util->init_attrs($self, qw/m18/);
    
    return $self;
}

package T1_2;
use base 'T1';


package T1_3;
use base 'T1_2';



1;
