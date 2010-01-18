package Object::Simple::Util;
use strict;
use warnings;
use Carp 'croak';

sub init_attrs {
    
    my ($self, $obj, @attrs) = @_;
    
    foreach my $attr (@attrs) {
        $obj->$attr($obj->{$attr}) if exists $obj->{$attr};
    }
    
    return $self;
}

sub class_attrs {
    my ($self, $invocant) = @_;
    
    my $class = ref $invocant || $invocant;
    
    no strict 'refs';
    ${"${class}::CLASS_ATTRS"} ||= {};
    my $class_attrs = ${"${class}::CLASS_ATTRS"};
    
    return $class_attrs;
}

my %VALID_VARIABLE_TYPE = map {$_ => 1} qw/array hash/;
my %VALID_INITIALIZE_OPTIONS_KEYS = map {$_ => 1} qw/clone default/;

sub create_accessor {
    my ($self, $class, $accessor_name, $options, $accessor_type) = @_;
    
    # Accessor type
    $accessor_type ||= '';
    
    # Get accessor options
    my ($build, $auto_build, $read_only, $weak, $type, $convert, $deref, $trigger, $initialize, $clone)
      = @{$options}{qw/build auto_build read_only weak type convert deref trigger initialize clone/};
    
    # chained
    my $chained =   exists $options->{chained} ? $options->{chained} : 1;
    
    # Passed value expression
    my $value = '$_[0]';
    
    # Check type
    croak("'type' option must be 'array' or 'hash' (${class}::$accessor_name)")
      if $type && !$VALID_VARIABLE_TYPE{$type};
    
    # Check deref
    croak("'deref' option must be specified with 'type' option (${class}::$accessor_name)")
      if $deref && !$type;
    
    # Beginning of accessor source code
    my $source =
                qq/sub {\n/ .
                qq/    package $class;\n/ .
                qq/    my \$self = shift;\n/;
    
    # Variable to strage
    my $strage;
    if ($accessor_type eq 'ClassAttr') {
        # Strage package Varialbe in case class accessor
        $strage = "Object::Simple::Util->class_attrs(\$self)->{'$accessor_name'}";
        $source .=
                qq/    Carp::croak("${class}::$accessor_name must be called from class, not instance")\n/ .
                qq/      if ref \$self;\n/;
    }
    else {
        # Strage hash in case normal accessor
        $strage = "\$self->{'$accessor_name'}";
    }
    
    # Create temporary variable if there is type or convert option
    $source .=    qq/    my \$value;\n/ if $type || $convert;

    # Invalid 'build' option
    croak "'build', or 'default' option must be scalar or code ref (${class}::$accessor_name)"
      unless !ref $build || ref $build eq 'CODE';

    # Automatically call build method
    if ($initialize) {
        
        # Check initialize data type
        croak("'initialize' option must be hash reference (${class}::$accessor_name)")
          unless ref $initialize eq 'HASH';
        
        # Check initialize valid key
        foreach my $key (keys %$initialize) {
            croak("'initialize' option must be 'clone', or 'default' (${class}::$accessor_name)")
              unless $VALID_INITIALIZE_OPTIONS_KEYS{$key};
        }
        
        # Check clone option
        my $clone = $initialize->{clone};
        croak("'initialize'-'clone' opiton must be 'scalar', 'array', 'hash', or code reference (${class}::$accessor_name)")
          if !defined $clone ||
             !($clone eq 'scalar' || $clone eq 'array' ||
               $clone eq 'hash' || ref $clone eq 'CODE');
        
        # Check default option
        croak("'initialize'-'default' option must be scalar, or code ref (${class}::$accessor_name)")
          if exists $initialize->{default} && 
             !(!ref $initialize->{default} || ref $initialize->{default} eq 'CODE');
        
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        Object::Simple::Util->clone_prototype(\n/ .
                qq/            \$self,\n/ .
                qq/            '$accessor_name',\n/ .
                qq/            \$options->{initialize}\n/ .
                qq/        );\n/ .
                qq/    }\n/;
    }
    elsif ($clone) {
        
        croak("'clone' opiton must be 'scalar', 'array', 'hash', or code reference (${class}::$accessor_name)")
          if !($clone eq 'scalar' || $clone eq 'array' || $clone eq 'hash' || ref $clone eq 'CODE');
        
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        Object::Simple::Util->clone_prototype(\n/ .
                qq/            \$self,\n/ .
                qq/            '$accessor_name',\n/ .
                qq/            \$options\n/ .
                qq/        );\n/ .
                qq/    }\n/;
    }
    elsif ($auto_build){
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/;
        
        if(ref $auto_build eq 'CODE') {
            $source .=
                qq/        \$options->{auto_build}->(\$self);\n/;
        }
        else {
            my $build_method;
            if( $accessor_name =~ s/^(_*)// ){
                $build_method = $1 . "build_$accessor_name";
            }
            
            $source .=
                qq/        \$self->$build_method;\n/;
        }
        
        $source .=
                qq/    }\n/;
    }
    elsif ($build) {
        
        # Build
        $source .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        \$self->$accessor_name(\n/;
        
        # Code ref
        if (ref $build) {
            $source .=
                qq/            scalar \$options->{build}->(\$self)\n/;
        }
        
        # Scalar
        else {
            $source .=
                qq/            scalar \$options->{build}\n/;
        }
        
        # Close
        $source .=
                qq/        )\n/ .
                qq/    }\n/;
    }
    
    # Read only accesor
    if ($read_only){
        $source .=
                qq/    Carp::croak("${class}::$accessor_name is read only") if \@_ > 0;\n/;
    }
    
    # Read and write accessor
    else {
        $source .=
                qq/    if(\@_ > 0) {\n/;
        
        # Variable type
        if($type) {
            if($type eq 'array') {
                $source .=
                qq/        \$value = ref \$_[0] eq 'ARRAY' ? \$_[0] : !defined \$_[0] ? undef : [\@_];\n/;
            }
            else {
                $source .=
                qq/        \$value = ref \$_[0] eq 'HASH' ? \$_[0] : !defined \$_[0] ? undef : {\@_};\n/;
            }
            $value = '$value';
        }
        
        # Convert to object;
        if ($convert) {
            if(ref $convert eq 'CODE') {
                $source .=
                qq/        \$value = \$options->{convert}->($value);\n/;
            }
            else {
                require Scalar::Util;
                
                $source .=
                qq/        require $convert;\n/ .
                qq/        \$value = defined $value && !Scalar::Util::blessed($value) ? $convert->new($value) : $value ;\n/;
            }
            $value = '$value';
        }
        
        # Save old value
        if ($trigger) {
            $source .=
                qq/        my \$old = $strage;\n/;
        }
        
        # Set value
        $source .=
                qq/        $strage = $value;\n/;
        
        # Weaken
        if ($weak) {
            require Scalar::Util;
            $source .=
                qq/        Scalar::Util::weaken($strage) if ref $strage;\n/;
        }
        
        # Trigger
        if ($trigger) {
            croak("'trigger' option must be code reference (${class}::$accessor_name)")
              unless ref $trigger eq 'CODE';
            
            $source .=
                qq/        \$options->{trigger}->(\$self, \$old);\n/;
        }
        
        # Return self if chained
        if ($chained) {
            $source .=
                qq/        return \$self;\n/;
        }
        
        $source .=
                qq/    }\n/;
    }
    
    # Dereference
    if ($deref) {
        if ($type eq 'array') {
            $source .=
                qq/    return wantarray ? \@{$strage} : $strage;\n/;
        }
        else {
            $source .=
                qq/    return wantarray ? \%{$strage} : $strage;\n/;
        }
    }
    
    # No dereference
    else {
        $source .=
                qq/    return $strage;\n/;
    }
    
    # End of accessor source code
    $source .=    qq/}\n\n/;
    
    my $code = eval $source;
    
    croak("$source\n:$@") if $@;
                
    return $code;
}

sub create_class_accessor  { shift->create_accessor(@_[0 .. 2], 'ClassAttr') }

sub create_dual_accessor {
    my ($self, $class, $accessor_name, $options) = @_;
    
    my $object_accessor = $self->create_accessor($class, $accessor_name, $options);
    
    my $class_accessor  = $self->create_class_accessor($class, $accessor_name, $options);
    
    my $source = qq/sub {\n/ .
                 qq/    package $class;\n/ .
                 qq/    my \$invocant = shift;\n/ .
                 qq/    if (ref \$invocant) {\n/ .
                 qq/        return wantarray ? (\$object_accessor->(\$invocant, \@_))\n/ .
                 qq/                         : \$object_accessor->(\$invocant, \@_);\n/ .
                 qq/    }\n/ .
                 qq/    else {\n/ .
                 qq/        return wantarray ? (\$class_accessor->(\$invocant, \@_))\n/ .
                 qq/                         : \$class_accessor->(\$invocant, \@_);\n/ .
                 qq/    }\n/ .
                 qq/}\n\n/;
    
    my $code = eval $source;
    
    croak("$source\n:$@") if $@;
                
    return $code;
}

sub clone_prototype {
    my $self          = shift;
    my $invocant      = shift;
    my $accessor_name = shift;
    my $options = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    
    # clone option
    my $clone   = $options->{clone};
    
    # Check clone option
    unless (ref $clone eq 'CODE') {
        if ($clone eq 'scalar') {
            $clone = sub {shift};
        }
        elsif ($clone eq 'array') {
            $clone = sub { return [@{shift || [] }] };
        }
        elsif ($clone eq 'hash') {
            $clone = sub { return { %{shift || {} } } };
        }
    }
    
    # build options
    my $default = exists $options->{default}
                ? $options->{default}
                : $options->{build};
    
    # get Default value when it is code ref
    $default = $default->() if ref $default eq 'CODE';
    
    # Called from object
    if (my $class = ref $invocant) {
        $invocant->$accessor_name($clone->(scalar $class->$accessor_name));
    }
    else {
        # Called from class
        my $super =  do {
            no strict 'refs';
            ${"${invocant}::ISA"}[0];
        };
        my $value = eval{$super->can($accessor_name)}
                       ? $clone->(scalar $super->$accessor_name)
                       : $default;
                          
        $invocant->$accessor_name($value);
    }
}

=head1 NAME
 
Object::Simple::Util - Object::Simple utility

=head1 Methods

=head2 init_attrs

Initalize attributes

    Object::Simple::Util->init_attrs($self, qw/foo bar/)

This method is used in overrided new method.
If you use trigger(or weak,convert) option like the following way,
 you are better to call this method.

    __PACKAGE__->attr('error', trigger => sub {
        my $self = shift;
        
        $self->state('error') if $self->error;
    });
    
    __PACKAGE__->attr('state');

    sub new {
        my $self = shift->SUPER::new(@_);
        
        Object::Simple::Util->init_attrs($self, 'error');
        
        return $self;
    }

You are get same result in two case.

    # Initialize from constructor
    YourClass->new(error => 'message');
    
    # Using accessor
    my $obj = YourClass->new;
    $obj->error('message');

If attribute is exsits in constructor, reset the value calling accessor.
The two is same.

        Object::Simple::Util->init_attrs($self, 'error');
        
        $self->error($self->{error}) if exists $self->{error};

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

