package Object::Simple::OldUtil;
use strict;
use warnings;
use Carp 'croak';

sub class_infos { $Object::Simple::Old::CLASS_INFOS ||= {} };

# Get leftmost self and parent classes
sub get_leftmost_isa {
    my ($self, $class) = @_;
    
    my @leftmost_isa;
    
    # Sortcut
    return unless $class;
    
    my $leftmost_parent = $class;
    push @leftmost_isa, $leftmost_parent;
    no strict 'refs';
    while( $leftmost_parent = ${"${leftmost_parent}::ISA"}[0] ) {
        push @leftmost_isa, $leftmost_parent;
    }
    
    return \@leftmost_isa;
}

# Get upper accessor options
sub get_super_accessor_options {
    my ($self, $class, $accessor_name) = @_;
    
    # Base class
    my $base_class = $class;
    
    # Get super class accessor option 
    no strict 'refs';
    while($base_class = ${"${base_class}::ISA"}[0]) {
        return ($self->class_infos->{$base_class}{accessors}{$accessor_name}{options}, $base_class)
          if $self->class_infos->{$base_class}{accessors}{$accessor_name}{options};
    }
    
    # Not found
    return;
}

# Include mixin classes
sub include_mixin_classes {
    my ($self, $caller_class) = @_;
    
    my $class_infos = $self->class_infos;
    
    # Get mixin classes
    my $mixin_classes = $class_infos->{$caller_class}{mixins};
    
    croak("mixins must be array reference ($caller_class)") 
      unless ref $mixin_classes eq 'ARRAY';
    
    # Mixin class accessor options
    my $mixins_accessor_options = {};
    
    # Deparse object
    my $deparse;
    
    # Include mixin classes
    no warnings 'redefine';
    foreach my $mixin_class (reverse @$mixin_classes) {
        croak("Mixin class '$mixin_class' is invalid class name ($caller_class)")
          if $mixin_class =~ /[^\w:]/;
        
        unless($mixin_class->can('isa')) {
            eval "require $mixin_class;";
            croak("$@") if $@;
        }
        
        my $deparse_possibility
          = $self->mixin_method_deparse_possibility($mixin_class);
        
        my $deparse;
        if ($deparse_possibility) {
            require B::Deparse;
            $deparse ||= B::Deparse->new;
        }
        
        # Import all methods
        no strict 'refs';
        foreach my $method ( keys %{"${mixin_class}::"} ) {
            next unless defined &{"${mixin_class}::$method"};
            
            my $derive_class
              = $class_infos->{$mixin_class}{methods}{$method}{derive};
            
            my $deparse_method = $derive_class
                               ? \&{"${derive_class}::$method"}
                               : \&{"${mixin_class}::$method"};
            
            my $code_ref;
            if ($deparse_possibility) {
                my $code = $deparse->coderef2text($deparse_method);
                $code =~ /^{\s*package\s+(.+?)\s*;/;
                my $package = $1 || '';
                
                if ((($derive_class && $package eq $derive_class) || $package eq $mixin_class)
                  && $code =~ /->SUPER::/) 
                {
                    $code =~ s/->SUPER::(.+?)\(/->Object::Simple::Old::call_super([ '$1', '$caller_class', '$mixin_class'], /smg;
                    $code_ref = eval "sub $code";
                    croak("Code copy error : \n $code\n $@") if $@;
                }
                else {
                    $code_ref = \&{"${mixin_class}::$method"};
                }
            }
            else {
                $code_ref = \&{"${mixin_class}::$method"};
            }
            
            $class_infos->{$caller_class}{mixin}{$mixin_class}{methods}{$method} = $code_ref;
            
            next if defined &{"${caller_class}::$method"};
            *{"${caller_class}::$method"} = $code_ref;
            $class_infos->{$caller_class}{methods}{$method}{derive} = 
              $class_infos->{$mixin_class}{methods}{$method}{derive} || $mixin_class;
        }
    }
    
    # Merge accessor to caller class
    my %accessors;
    foreach my $class (@$mixin_classes, $caller_class) {
        %accessors = (%accessors, %{$class_infos->{$class}{accessors}})
          if $class_infos->{$class}{accessors};
    }
    $class_infos->{$caller_class}{accessors} = \%accessors;
}

sub mixin_method_deparse_possibility {
    my ($self, $mixin_class) = @_;
    
    # Class infos
    my $class_infos = $self->class_infos;
    
    # Has mixin classes
    return 1
      if ref $class_infos->{$mixin_class}{mixins} &&
         @{$class_infos->{$mixin_class}{mixins}};
    
    # Call SUPER method
    my $module_path = join('/', split(/::/, $mixin_class)) . '.pm';
    my $module_file = $INC{$module_path};
    if ($module_file && -r $module_file) {
        # Open
        open my $fh, "<", $module_file
          or return 1;
        
        # Slurp
        local $/;
        my $content = <$fh>;
        
        if (index($content, '->SUPER::') == -1) {
            return 0;
        }
    }
    return 1;
}
 
# Merge self and super accessor option
sub merge_self_and_super_accessors {
    my ($self, $class) = @_;
    
    # Class infos
    my $class_infos = $self->class_infos;
    
    # Return cache if cached 
    return $class_infos->{$class}{merged_accessors}
      if $class_infos->{$class}{merged_accessors};
    
    # Get self and super classed
    my $self_and_super_classes = $self->get_leftmost_isa($class);
    
    # Get merged accessor options 
    my $accessors = {};
    foreach my $class (reverse @$self_and_super_classes) {
        $accessors = {%{$accessors}, %{$class_infos->{$class}{accessors}}}
            if defined $class_infos->{$class}{accessors};
    }
    
    # Cached
    $class_infos->{$class}{merged_accessors} = $accessors;
    
    return $accessors;
}

# Create constructor
sub create_constructor {
    my ($self, $class) = @_;
    
    # Get merged accessors
    my $accessors = $self->merge_self_and_super_accessors($class);
    my $object_accessors = {};
    my $translate_accessors = {};
    
    # Attr or Transalte
    foreach my $accessor (keys %$accessors) {
        my $accessor_type = $accessors->{$accessor}{type} || '';
        if (   $accessor_type eq 'Attr' 
            || $accessor_type eq 'ClassObjectAttr'
            || $accessor_type eq 'HybridAttr')
        {
            $object_accessors->{$accessor} = $accessors->{$accessor};
        }
        elsif ($accessor_type eq 'Translate') {
            $translate_accessors->{$accessor} = $accessors->{$accessor};
        }
    }
    
    # Create instance
    my $code =  qq/package Object::Simple::Old::Constructors::${class};\n/ .
                qq/sub new {\n/ .
                qq/    my \$class = shift;\n/ .
                qq/    my \$self = !(\@_ % 2)           ? {\@_}       :\n/ .
                qq/               ref \$_[0] eq 'HASH' ? {\%{\$_[0]}} :\n/ .
                qq/                                     {\@_, undef};\n/ .
                qq/    bless \$self, \$class;\n/;
    
    # Attribute which have trigger option
    my @accessors_having_trigger;
    
    # Customize initialization
    foreach my $accessor_name (keys %$object_accessors) {
        
        # Convert option
        if ($accessors->{$accessor_name}{options}{convert}) {
            if(ref $accessors->{$accessor_name}{options}{convert} eq 'CODE') {
                $code .=
                qq/    \$self->{'$accessor_name'} = Object::Simple::OldUtil->class_infos->{'$class'}{merged_accessors}{'$accessor_name'}{options}{convert}->(\$self->{'$accessor_name'})\n/ .
                qq/        if exists \$self->{'$accessor_name'};\n/;
            }
            else {
                require Scalar::Util;
                
                my $convert = $accessors->{$accessor_name}{options}{convert};
                $code .=
                qq/    require $convert;\n/ .
                qq/    \$self->{'$accessor_name'} = $convert->new(\$self->{'$accessor_name'}) if defined \$self->{'$accessor_name'} && !Scalar::Util::blessed(\$self->{'$accessor_name'});\n/;
            }
        }
        
        # Default option
        if(defined $accessors->{$accessor_name}{options}{default}) {
            if(ref $accessors->{$accessor_name}{options}{default} eq 'CODE') {
                $code .=
                qq/    \$self->{'$accessor_name'} = \$CLASS_INFOS->{'$class'}{merged_accessors}{'$accessor_name'}{options}{default}->()\n/ .
                qq/      unless exists \$self->{'$accessor_name'};\n/;
            }
            elsif(!ref $accessors->{$accessor_name}{options}{default}) {
                $code .=
                qq/    \$self->{'$accessor_name'} = \$CLASS_INFOS->{'$class'}{merged_accessors}{'$accessor_name'}{options}{default}\n/ .
                qq/      unless exists \$self->{'$accessor_name'};\n/;
            }
            else {
                croak("Value of 'default' option must be a code reference or constant value(${class}::$accessor_name)");
            }
        }
        
        # Weak option
        if($accessors->{$accessor_name}{options}{weak}) {
            require Scalar::Util;
            $code .=
                qq/    Scalar::Util::weaken(\$self->{'$accessor_name'}) if ref \$self->{'$accessor_name'};\n/;
        }
        
        # Regist accessoribute which have trigger option
        push @accessors_having_trigger, $accessor_name
            if $accessors->{$accessor_name}{options}{trigger};
    }
    
    # Trigger option
    foreach my $accessor_name (@accessors_having_trigger) {
        $code .=
            qq/    Object::Simple::OldUtil->class_infos->{'$class'}{merged_accessors}{'$accessor_name'}{options}{trigger}->(\$self) if exists \$self->{'$accessor_name'};\n/;
    }
    
    # Translate option
    foreach my $accessor_name (keys %$translate_accessors) {
        $code .=
            qq/    \$self->$accessor_name(delete \$self->{'$accessor_name'}) if exists \$self->{'$accessor_name'};\n/;
    }
    
    # Return
    $code .=    qq/    return \$self;\n/ .
                qq/}\n/;
}

# Valid type
my %VALID_VARIABLE_TYPE = map {$_ => 1} qw/array hash/;
my %VALID_INITIALIZE_OPTIONS_KEYS = map {$_ => 1} qw/clone default/;

### Output accessor will be deleted in future ###
# Create accessor for output
sub create_output_accessor {
    my ($self, $class, $accessor_name, $options) = @_;
    
    my $target = $options->{target};
    
    my $source =  qq/sub {\n/ .
                  qq/    package $class;\n/ .
                  qq/    my (\$self, \$output) = \@_;\n/ .
                  qq/    my \$value = \$self->$target;\n/ .
                  qq/    \$\$output = \$value;\n/ .
                  qq/    return \$self\n/ .
                  qq/}\n\n/;

    my $code = eval $source;
    
    croak("$source\n:$@") if $@;
                
    return $code;
}

### Translate accessor will be deleted in future ###
# Create accessor for delegate
sub create_translate_accessor {
    my ($self, $class, $accessor_name, $options) = @_;
    
    my $target = $options->{target} || '';
    
    croak("${class}::$accessor_name '$target' is invalid. Translate 'target' option must be like 'method1->method2'")
      unless $target =~ /^(([a-zA-Z_][\w_]*)->)+([a-zA-Z_][\w_]*)$/;
    
    my $source = qq/sub {\n/ .
                 qq/    package $class;\n/ .
                 qq/    my \$self = shift;\n/ .
                 qq/    if (\@_) {\n/ .
                 qq/        \$self->$target(\@_);\n/ .
                 qq/        return \$self;\n/ .
                 qq/    }\n/ .
                 qq/    return wantarray ? (\$self->$target) : \$self->$target;\n/ .
                 qq/}\n\n/;
                
    my $code = eval $source;
    
    croak("$source\n:$@") if $@;
                
    return $code;
}

# Valid accessor options(Attr)
my %VALID_OBJECT_ACCESSOR_OPTIONS 
  = map {$_ => 1} qw(default chained weak read_only build auto_build type convert deref trigger translate extend);

# Valid class accessor options(ClassAttr)
my %VALID_CLASS_ACCESSOR_OPTIONS
  = map {$_ => 1} qw(chained weak read_only build auto_build type convert deref trigger translate extend initialize clone);

# Valid Hybrid accessor options(HybridAttr)
my %VALID_HYBRID_ACCESSOR_OPTIONS
  = map {$_ => 1} qw(chained weak read_only build auto_build type convert deref trigger translate extend initialize clone);

# (Output accessor is deprecated)
# Valid class output accessor options(Output)
my %VALID_OUTPUT_OPTIONS = map {$_ => 1} qw(target);

# (Translate accessor is deprecated)
# Valid translate accessor option(Translate)
my %VALID_TRANSLATE_OPTIONS = map {$_ => 1} qw(target);

my $VALID_ACCESSOR_OPTIONS = {
    Attr            => \%VALID_OBJECT_ACCESSOR_OPTIONS,
    ClassAttr       => \%VALID_CLASS_ACCESSOR_OPTIONS,
    HybridAttr      => \%VALID_HYBRID_ACCESSOR_OPTIONS,
    
    # (Deprecated)
    ClassObjectAttr => \%VALID_HYBRID_ACCESSOR_OPTIONS,
    # (Deprecated)
    Output          => \%VALID_OUTPUT_OPTIONS,
    # (Deprecated)
    Translate       => \%VALID_TRANSLATE_OPTIONS
};

# Check accessor options
sub check_accessor_option {
    my ($self, $accessor_name, $class, $accessor_options, $accessor_type ) = @_;
    
    my $valid_accessor_options = $VALID_ACCESSOR_OPTIONS->{$accessor_type};
    
    foreach my $accessor_option_name (keys %$accessor_options){
        croak("${class}::$accessor_name '$accessor_option_name' is invalid accessor option.")
          unless $valid_accessor_options->{$accessor_option_name};
    }
}

# Define MODIFY_CODE_ATTRIBUTRS subroutine
my %VALID_ACCESSOR_TYPES = map {$_ => 1} qw/Attr ClassAttr HybridAttr ClassObjectAttr Output Translate/;
sub define_MODIFY_CODE_ATTRIBUTES {
    my ($self, $class) = @_;
    
    # MODIFY_CODE_ATTRIBUTES
    my $code = sub {
        my ($class, $code_ref, $accessor_type) = @_;
        
        # Accessor type is not exist
        croak("Accessor type '$accessor_type' is not exist. " .
              "Accessor type must be 'Attr', 'ClassAttr', " . 
              "'HybridAttr'")
          unless $VALID_ACCESSOR_TYPES{$accessor_type};
        
        # Add 
        $self->add_accessor_info([$class, $code_ref, $accessor_type]);
        
        return;
    };
    
    no strict 'refs';
    *{"${class}::MODIFY_CODE_ATTRIBUTES"} = $code;
}

sub add_accessor_info { 
    my ($self, $accessor_info) = @_;
    push @Object::Simple::Old::ACCESSOR_INFOS, $accessor_info;
}

# Class attributes
sub class_attrs {
    my ($self, $invocant) = @_;
    
    my $class = ref $invocant || $invocant;
    
    no strict 'refs';
    ${"${class}::CLASS_ATTRS"} ||= {};
    my $class_attrs = ${"${class}::CLASS_ATTRS"};
    
    return $class_attrs;
}

# Class attribute is exsist?
sub exists_class_attr {
    my ($self, $invocant, $accessor_name) = @_;
    
    my $class = ref $invocant || $invocant;

    return exists $self->class_attrs($class)->{$accessor_name};
}

# Delete class attribute
sub delete_class_attr {
    my ($self, $invocant, $accessor_name) = @_;

    my $class = ref $invocant || $invocant;

    return delete $self->class_attrs($class)->{$accessor_name};
}

sub init_attrs {
    
    my ($self, $obj, @attrs) = @_;
    
    foreach my $attr (@attrs) {
        $obj->$attr($obj->{$attr}) if exists $obj->{$attr};
    }
    
    return $self;
}

=head1 NAME
 
Object::Simple::OldUtil - Object::Simple internal utility

=head1 Methods

=head2 add_accessor_info

=head2 check_accessor_option

=head2 class_attrs

=head2 class_infos

=head2 clone_prototype

=head2 create_accessor

=head2 create_class_accessor

=head2 create_constructor

=head2 create_hybrid_accessor

=head2 create_output_accessor

=head2 create_translate_accessor

=head2 define_MODIFY_CODE_ATTRIBUTES

=head2 delete_class_attr

=head2 exists_class_attr

=head2 get_leftmost_isa

=head2 get_super_accessor_options

=head2 include_mixin_classes

=head2 init_attrs

=head2 merge_self_and_super_accessors

=head2 mixin_method_deparse_possibility

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

