package Object::Simple::Accessor;

use strict;
use warnings;
use Carp 'croak';

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

    # Check options
    _check_options($type, $options);
    
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
}

my %VALID_ACCESSOR_OPTIONS       = map { $_ => 1 } qw/build type deref/;
my %VALID_CLASS_ACCESSOR_OPTIONS  = map { $_ => 1 } qw/build type deref clone/;
my %VALID_HYBRID_ACCESSOR_OPTIONS = map { $_ => 1 } qw/build type deref clone/;

sub _check_options {
    my ($type, $options) = @_;
    
    foreach my $oname (keys %$options) {
        if ($type eq 'attr') {
            croak "'attr' option must be 'build', 'type', or 'deref'"
              unless $VALID_ACCESSOR_OPTIONS{$oname};
        }
        elsif ($type eq 'class_attr') {
            croak "'attr' option must be 'build', 'type', 'deref', or 'clone'"
              unless $VALID_CLASS_ACCESSOR_OPTIONS{$oname};
        }
        else {
            croak "'attr' option must be 'build', 'type', 'deref', or 'clone'"
              unless $VALID_HYBRID_ACCESSOR_OPTIONS{$oname};
        }
    }
}


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

