package Object::Simple::Accessor;

use strict;
use warnings;

use Object::Simple::Util;
use constant Util => 'Object::Simple::Util';
use base 'Exporter';

our @EXPORT_OK = qw/attr class_attr hybrid_attr/;

sub attr        { _create_accessor(shift, 'attr',        @_) }
sub class_attr  { _create_accessor(shift, 'class_attr',  @_) }
sub hybrid_attr { _create_accessor(shift, 'hybrid_attr', @_) }

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
                 
                 : $type eq 'hybrid_attr'
                 ? Util->create_hybrid_accessor($class, $attr, $options)
                 
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
    use Object::Simple::Accessor qw/attr class_attr hybrid_attr/;
    
    __PACKAGE__->attr(title   => 'Good day');
    __PACKAGE__->attr(authors => sub {[]});

=head1 Export

You can export 'attr', 'class_attr', 'hybrid_attr'.
If you want to know the usages, see L<Object::Simple::Base>

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

