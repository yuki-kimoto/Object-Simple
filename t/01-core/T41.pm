package T41;
use Object::Simple;

Object::Simple->resist_accessor_info('T41', 'm1', { default => 1 });
Object::Simple->resist_accessor_info('T41', 'm1_to', sub { target => 'm1' }, 'Output');

Object::Simple->build_class('T41');
