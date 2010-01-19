package T41;
use Object::Simple::Old;

Object::Simple::Old->resist_accessor_info('T41', 'm1', { default => 1 });
Object::Simple::Old->resist_accessor_info('T41', 'm1_to', sub { target => 'm1' }, 'Output');

Object::Simple::Old->build_class('T41');
