package Object::Simple::Accessor;

use strict;
use warnings;

use Object::Simple::Util;
use constant Util => 'Object::Simple::Util';
use base 'Exporter';

our @EXPORT_OK = qw/attr class_attr dual_attr hybrid_attr/;

sub attr        { _create_accessor(shift, 'attr',        @_) }
sub class_attr  { _create_accessor(shift, 'class_attr',  @_) }
sub dual_attr { _create_accessor(shift, 'dual_attr', @_) }

# alias of daul_attr
sub hybrid_attr { _create_accessor(shift, 'dual_attr', @_) }

sub _create_accessor {
    my ($class, $type, $attrs, @options) = @_;
    
    # Shorcut
    return unless $attrs;
    
    # To array
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Arrange options
    my $options = @options > 1 ? {@options} : {build => $options[0]};
    
    # Upgrade
    my $default = delete $options->{default};
    $options->{build} = $default if $default;
    
    foreach my $attr (@$attrs) {
        
        # Create accessor
        my $code = $type eq 'attr'
                 ? Util->create_accessor($class, $attr, $options)
                 
                 : $type eq 'class_attr'
                 ? Util->create_class_accessor($class, $attr, $options)
                 
                 : $type eq 'dual_attr'
                 ? Util->create_dual_accessor($class, $attr, $options)
                 
                 : undef;
        
        # Import
        no strict 'refs';
        *{"${class}::$attr"} = $code;
    }
    return $class;
}

=head1 NAME

Object::Simple::Accessor - Provide a ability to create a accessor

=head1 SYNOPSYS
    
    package YourModule;
    use Object::Simple::Accessor qw/attr class_attr dual_attr/;
    
    __PACKAGE__->attr(title   => 'Good day');
    __PACKAGE__->attr(authors => sub {[]});

=head1 Functions

You can export 'attr', 'class_attr', 'dual_attr'.

    use Object::Simple::Accessor qw/attr class_attr dual_attr/;

See L<Object::Simple::Base> to know the usage of these methods.

=head1 Purpose

L<Object::Simple::Base> provide a constructor and ability to create accessors
to this subclass.
    
    package YourClass;
    use base 'Object::Simple::Base';

But construcor and a ability to create accessors is linked.
L<Object::Simple::Accessor> provide only a ability to create accessors.

If you inherit other class, you provide a avility to create accessor to the class.

    package YourClass;
    use base 'LWP::UserAgent';
    
    use Object::Simple::Accessor 'attr';
    
    __PACKAGE__->attr('foo');

=head1 Author
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/Object-Simple>

Please tell me bug if you find.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

