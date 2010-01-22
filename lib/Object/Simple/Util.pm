package Object::Simple::Util;
use strict;
use warnings;
use Carp 'croak';

sub class_attrs {
    my ($self, $invocant) = @_;
    
    my $class = ref $invocant || $invocant;
    
    no strict 'refs';
    ${"${class}::CLASS_ATTRS"} ||= {};
    my $class_attrs = ${"${class}::CLASS_ATTRS"};
    
    return $class_attrs;
}

sub create_accessor {
    my ($self, $class, $attr, $options, $attr_type) = @_;
    
    # Attribute type
    $attr_type ||= '';
    
    # Options
    my $default = $options->{default};
    my $inherit = $options->{inherit};
    
    # Beginning of accessor
    my $source =
                qq/sub {\n/ .
                qq/    my \$self = shift;\n/;
    
    # Strage
    my $strage;
    if ($attr_type eq 'class') {
        # Class variable
        $strage = "Object::Simple::Util->class_attrs(\$self)->{'$attr'}";
        
        # Called from a instance
        $source .=
                qq/    Carp::croak("${class}::$attr must be called from a class, not a instance")\n/ .
                qq/      if ref \$self;\n/;
    }
    else {
        # Instance variable
        $strage = "\$self->{'$attr'}";
    }
    
    # Check 'default' option
    croak "'default' option must be scalar or code ref (${class}::$attr)"
      unless !ref $default || ref $default eq 'CODE';
    
    # Inherit
    if ($inherit) {
        # Check 'inherit' option
        croak("'inherit' opiton must be 'scalar_copy', 'array_copy', " . 
              "'hash_copy', or code reference (${class}::$attr)")
          unless $inherit eq 'scalar_copy' || $inherit eq 'array_copy'
              || $inherit eq 'hash_copy'   || ref $inherit eq 'CODE';
        
        # Inherit code
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        Object::Simple::Util->inherit_prototype(\n/ .
                qq/            \$self,\n/ .
                qq/            '$attr',\n/ .
                qq/            \$options\n/ .
                qq/        );\n/ .
                qq/    }\n/;
    }
    
    # Default
    elsif ($default) {
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        \$self->$attr(\n/;
            
        $source .= ref $default
              ? qq/            \$options->{default}->(\$self)\n/
              : qq/            \$options->{default}\n/;
        
        $source .=
                qq/        )\n/ .
                qq/    }\n/;
    }
    
    # Set and get
    $source .=  qq/    if(\@_ > 0) {\n/ .
                qq/        $strage = \$_[0];\n/ .
                qq/        return \$self\n/ .
                qq/    }\n/ .
                qq/    return $strage;\n/;
    
    # End of accessor source code
    $source .=  qq/}\n/;
    
    # Code
    my $code = eval $source;
    croak("$source\n:$@") if $@;
                
    return $code;
}

sub create_class_accessor  { shift->create_accessor(@_[0 .. 2], 'class') }

sub create_dual_accessor {
    my ($self, $class, $accessor_name, $options) = @_;
    
    # Accessor
    my $accessor = $self->create_accessor($class, $accessor_name, $options);
    
    # Class accessor
    my $class_accessor
      = $self->create_class_accessor($class, $accessor_name, $options);
    
    # Dual accessor
    my $code = sub {
        my $invocant = shift;
        return ref $invocant ? $accessor->($invocant, @_)
                             : $class_accessor->($invocant, @_);
    };
    
    return $code;
}

sub inherit_prototype {
    my $self          = shift;
    my $invocant      = shift;
    my $accessor_name = shift;
    my $options = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    
    # inherit option
    my $inherit   = $options->{inherit};
    
    # Check inherit option
    unless (ref $inherit eq 'CODE') {
        if ($inherit eq 'scalar_copy') {
            $inherit = sub { $_[0] };
        }
        elsif ($inherit eq 'array_copy') {
            $inherit = sub { return [@{$_[0]}] };
        }
        elsif ($inherit eq 'hash_copy') {
            $inherit = sub { return { %{$_[0]} } };
        }
    }
    
    # default options
    my $default = $options->{default};
    
    # get Default value when it is code ref
    $default = $default->() if ref $default eq 'CODE';
    
    # Called from object
    if (my $class = ref $invocant) {
        $invocant->$accessor_name($inherit->($class->$accessor_name));
    }
    else {
        # Called from class
        my $super =  do {
            no strict 'refs';
            ${"${invocant}::ISA"}[0];
        };
        my $value = eval{$super->can($accessor_name)}
                       ? $inherit->($super->$accessor_name)
                       : $default;
                          
        $invocant->$accessor_name($value);
    }
}

=head1 NAME
 
Object::Simple::Util - Object::Simple utility

=head1 Author
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/object-simple>

Please tell me bug if you find.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1; # End of Object::Simple

