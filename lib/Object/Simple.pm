package Object::Simple;
use 5.008_001;
use strict;
use warnings;
 
use Carp 'croak';

# Meta imformation
our $CLASS_INFOS = {};

# Object::Simple::Util
our $UTIL = 'Object::Simple::Util';

# Classes which need to build
our @BUILD_NEED_CLASSES;

# Already build class;
our %ALREADY_BUILD_CLASSES;
 
# Attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ACCESSOR_INFOS;
 
# Valid import option
my %VALID_IMPORT_OPTIONS = map {$_ => 1} qw(base mixins);

# Import
sub import {
    my ($self, %options) = @_;
    
    # Shortcut
    return unless $self eq 'Object::Simple';
    
    # Get caller class
    my $caller_class = caller;
    
    # Check import option
    foreach my $key (keys %options) {
        croak("'$key' is invalid import option ($caller_class)")
          unless $VALID_IMPORT_OPTIONS{$key};
    }
    
    # Resist base class to meta information
    $Object::Simple::CLASS_INFOS->{$caller_class}{base} = $options{base};
    
    # Regist mixin classes to meta information
    $Object::Simple::CLASS_INFOS->{$caller_class}{mixins} = $options{mixins};
    
    # Adapt strict and warnings pragma to caller class
    strict->import;
    warnings->import;
    
    # Define MODIFY_CODE_ATTRIBUTES subroutine of caller class
    $UTIL->define_MODIFY_CODE_ATTRIBUTES($caller_class);
    
    # Push classes which need build
    push @BUILD_NEED_CLASSES, $caller_class;
    
    return 1;
}
 
# Unimport
sub unimport {
    
    # Get caller class
    my $caller_class = caller;
    
    # Delete MODIFY_CODE_ATTRIBUTES subroutine of caller class
    no strict 'refs';
    delete ${$caller_class . '::'}{MODIFY_CODE_ATTRIBUTES};
}
 
# New
sub new {
    my $invocant = shift;

    # Convert to class name
    my $class = ref $invocant || $invocant;
    
    # Call constructor
    return $CLASS_INFOS->{$class}{constructor}->($class,@_)
        if $CLASS_INFOS->{$class}{constructor};
    
    # Search super class constructor if constructor is not resited
    foreach my $super_class (@{$UTIL->get_leftmost_isa($class)}) {
        if($CLASS_INFOS->{$super_class}{constructor}) {
            $CLASS_INFOS->{$class}{constructor}
              = $CLASS_INFOS->{$super_class}{constructor};
            
            return $CLASS_INFOS->{$class}{constructor}->($class,@_);
        }
    }
}

# Build class(create accessor, include mixin class, and create constructor)
my %VALID_BUILD_CLASS_OPTIONS = map {$_ => 1} qw(all class);

# Build all classes
sub build_all_classes {
    my $self = shift;
    $self->build_class({all => 1});
}

# Build class
sub build_class {
    my ($self, $options) = @_;
    
    # passed class name
    unless (ref $options) {
        $options = {class => $options};
    }
    
    # Attribute names
    my $accessor_names = {};
    
    # Accessor code
    my $accessor_code = '';
    
    # Get caller class
    my $build_need_class = $options->{class} || caller;

    # check build_class options
    foreach my $key (keys %$options) {
        croak("'$key' is invalid build_class option")
          unless $VALID_BUILD_CLASS_OPTIONS{$key};
    }
    
    # Parse symbol table and create accessors code
    while (my $accessor_info = shift @Object::Simple::ACCESSOR_INFOS) {
        # CODE_ATTRIBUTE infomation
        my ($class, $accessor_options, $accessor_type, $accessor_name) = @$accessor_info;
        
        # Parse symbol tabel to find code reference correspond to accessor names
        unless($accessor_names->{$class}) {
            $accessor_names->{$class} = {};
            
            no strict 'refs';
            foreach my $sym (values %{"${class}::"}) {
                next unless ref(*{$sym}{CODE}) eq 'CODE';
                $accessor_names->{$class}{*{$sym}{CODE}} = *{$sym}{NAME};
            }
        }
        
        # Get accessor name
        $accessor_name ||= $accessor_names->{$class}{$accessor_options};
        
        # Get accessor options
        my @accessor_options = $accessor_options->();
        $accessor_options = ref $accessor_options[0] eq 'HASH'
                          ? $accessor_options[0] 
                          : {@accessor_options};
        
        # Check accessor option
        $UTIL->check_accessor_option($accessor_name, $class, $accessor_options,
                                     $accessor_type);
        
        # Resist accessor type and accessor options
        @{$Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}}{qw/type options/}
          = ($accessor_type, $accessor_options);
    }
    
    # Resist classes which need building
    my @build_need_classes;
    if ($options->{all}) {
        # Select build needing class
        @build_need_classes = grep {!$ALREADY_BUILD_CLASSES{$_}}
                                   @Object::Simple::BUILD_NEED_CLASSES;
        
        # Clear BUILD_NEED_CLASSES
        @Object::Simple::BUILD_NEED_CLASSES = ();
    }
    else{
        @build_need_classes = ($build_need_class)
          unless $ALREADY_BUILD_CLASSES{$build_need_class};
    }
    
    # Inherit base class and Object::Simple, and include mixin classes
    foreach my $class (@build_need_classes) {
        # Delete MODIFY_CODE_ATTRIBUTES
        {
            no strict 'refs';
            delete ${$class . '::'}{MODIFY_CODE_ATTRIBUTES};
        }
        
        # Inherit base class
        no strict 'refs';
        if( my $base_class = $Object::Simple::CLASS_INFOS->{$class}{base}) {
            @{"${class}::ISA"} = ();
            push @{"${class}::ISA"}, $base_class;
            
            croak("Base class '$base_class' is invalid class name ($class)")
              if $base_class =~ /[^\w:]/;
            
            unless($base_class->can('isa')) {
                eval "require $base_class;";
                croak("$@") if $@;
            }
        }
        
        # Check if inherit is available
        
        
        # Inherit Object::Simple
        push @{"${class}::ISA"}, 'Object::Simple';
        
        # Include mixin classes
        $UTIL->include_mixin_classes($class)
          if $Object::Simple::CLASS_INFOS->{$class}{mixins};
    }

    # Create constructor and resist accessor code
    foreach my $class (@build_need_classes) {
        my $accessors = $Object::Simple::CLASS_INFOS->{$class}{accessors};
        foreach my $accessor_name (keys %$accessors) {
            
            # Extend super class accessor options
            my $base_class = $class;
            while ($Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options}{extend}) {
                my ($super_accessor_options, $accessor_found_class)
                  = $UTIL->get_super_accessor_options($base_class, $accessor_name);
                
                delete $Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options}{extend};
                
                last unless $super_accessor_options;
                
                $Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options}
                  = {%{$super_accessor_options}, 
                     %{$Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options}}};
                
                $base_class = $accessor_found_class;
            }
            
            my $accessor_type = $accessors->{$accessor_name}{type};
            
            # Create accessor source code
            if ($accessor_type eq 'Translate') {
                ### Translate accessor will be deleted in future ###
                # Create translate accessor
                $accessor_code 
                  .= "package $class;\nsub $accessor_name " 
                  . $UTIL->create_translate_accessor($class, $accessor_name);
            }
            elsif ($accessor_type eq 'Output') {
                ### Output accessor will be deleted in future ###
                # Create output accessor
                $accessor_code
                  .= "package $class;\nsub $accessor_name " 
                  . $UTIL->create_output_accessor($class, $accessor_name);
            }
            elsif ($accessor_type eq 'ClassObjectAttr') {
                # Create class and object hibrid accessor
                $accessor_code
                  .= $UTIL->create_class_object_accessor($class, $accessor_name);
            }
            else {
                # Create normal accessor or class accessor
                $accessor_code
                  .= "package $class;\nsub $accessor_name " 
                  . $UTIL->create_accessor($class, $accessor_name, $accessor_type);
            }
        }
    }
    
    # Create accessor
    if($accessor_code){
        no warnings qw(redefine);
        eval $accessor_code;
        croak("$accessor_code\n:$@") if $@; # never occured
    }
    
    # Create constructor
    foreach my $class (@build_need_classes) {
        my $constructor_code = $UTIL->create_constructor($class);
        
        eval $constructor_code;
        croak("$constructor_code\n:$@") if $@; # never occured
        
        $Object::Simple::CLASS_INFOS->{$class}{constructor}
          = \&{"Object::Simple::Constructor::${class}::new"};
    }
    
    # Resist already build class
    $ALREADY_BUILD_CLASSES{$_} = 1 foreach @build_need_classes;
    
    return 1;
}

# Resit accessor information
sub resist_accessor_info {
    my ($self, $class, $accessor_name, $accessor_options, $accessor_type) = @_;
    
    # Rearrange accessor options
    my $accessor_options_  = ref $accessor_options eq 'HASH'
                           ? sub {$accessor_options}
                           : $accessor_options;
    
    # Default accessor type
    $accessor_type ||= 'Attr';
    
    # Add accessor info
    push @Object::Simple::ACCESSOR_INFOS,
         [$class, $accessor_options_, $accessor_type, $accessor_name];
}

# Call mixin method
sub call_mixin {
    my $self        = shift;
    my $mixin_class = shift || '';
    my $method      = shift || '';
    
    # Caller class
    my $caller_class = caller;
    
    # Method not exist
    croak(qq/"${mixin_class}::$method from $caller_class" is not exist/)
      unless $Object::Simple::CLASS_INFOS->{$caller_class}{mixin}{$mixin_class}{methods}{$method};
    
    return $Object::Simple::CLASS_INFOS->{$caller_class}{mixin}{$mixin_class}{methods}{$method}->($self, @_);
}

# Get mixin methods
sub mixin_methods {
    my $self         = shift;
    my $method       = shift || '';
    my $caller_class = caller;
    
    my $methods = [];
    foreach my $mixin_class (@{$Object::Simple::CLASS_INFOS->{$caller_class}{mixins}}) {
        
        push @$methods,
             $Object::Simple::CLASS_INFOS->{$caller_class}{mixin}{$mixin_class}{methods}{$method}
          if $Object::Simple::CLASS_INFOS->{$caller_class}{mixin}{$mixin_class}{methods}{$method};
    }
    return $methods;
}

# Call super method
sub call_super {
    my $self   = shift;
    my $method = shift;
    
    my $base_class;
    my $mixin_base_class;
    if (ref $method eq 'ARRAY') {
        $mixin_base_class = $method->[2];
        $base_class       = $method->[1];
        $method           = $method->[0];
    }
    $base_class  ||= caller;
    
    # Call last mixin method
    my $mixin_found = $mixin_base_class ? 0 : 1;
    if ($Object::Simple::CLASS_INFOS->{$base_class}{mixins}) {
        foreach my $mixin_class (reverse @{$Object::Simple::CLASS_INFOS->{$base_class}{mixins}}) {
            if ($mixin_base_class && $mixin_base_class eq $mixin_class) {
                $mixin_found = 1;
            }
            elsif ($mixin_found && $Object::Simple::CLASS_INFOS->{$base_class}{mixin}{$mixin_class}{methods}{$method}) {
                return $Object::Simple::CLASS_INFOS->{$base_class}{mixin}{$mixin_class}{methods}{$method}->($self, @_);
            }
        }
    }
    
    # Call base class method
    my @leftmost_isa;
    
    my $leftmost_parent = $base_class;
    push @leftmost_isa, $leftmost_parent;
    no strict 'refs';
    while($leftmost_parent = ${"${leftmost_parent}::ISA"}[0]) {
        return &{"${leftmost_parent}::$method"}($self, @_)
          if defined &{"${leftmost_parent}::$method"};
    }
    croak("Cannot locate method '$method' via base class of $base_class");
}

# Class attributes
sub class_attrs {
    my $invocant = shift;
    
    my $class = ref $invocant || $invocant;
    
    return $Object::Simple::CLASS_INFOS->{$class}{class_attrs};
}

# Class attribute is exsist?
sub exists_class_attr {
    my ($invocant, $accessor_name) = @_;
    
    my $class = ref $invocant || $invocant;

    return exists $Object::Simple::CLASS_INFOS->{$class}{class_attrs}{$accessor_name};
}

# Delete class attribute
sub delete_class_attr {
    my ($invocant, $accessor_name) = @_;

    my $class = ref $invocant || $invocant;

    return delete $Object::Simple::CLASS_INFOS->{$class}{class_attrs}{$accessor_name};
}

package Object::Simple::Util;
use strict;
use warnings;
use Carp 'croak';

# Object::Simple::Util
our $UTIL = 'Object::Simple::Util';

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
        return ($Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options}, $base_class)
          if $Object::Simple::CLASS_INFOS->{$base_class}{accessors}{$accessor_name}{options};
    }
    
    # Not found
    return;
}

# Include mixin classes
sub include_mixin_classes {
    my ($self, $caller_class) = @_;
    
    # Get mixin classes
    my $mixin_classes = $Object::Simple::CLASS_INFOS->{$caller_class}{mixins};
    
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
          = $UTIL->mixin_method_deparse_possibility($mixin_class);
        
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
              = $Object::Simple::CLASS_INFOS->{$mixin_class}{methods}{$method}{derive};
            
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
                    $code =~ s/->SUPER::(.+?)\(/->Object::Simple::call_super([ '$1', '$caller_class', '$mixin_class'], /smg;
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
            
            $Object::Simple::CLASS_INFOS->{$caller_class}{mixin}{$mixin_class}{methods}{$method} = $code_ref;
            
            next if defined &{"${caller_class}::$method"};
            *{"${caller_class}::$method"} = $code_ref;
            $Object::Simple::CLASS_INFOS->{$caller_class}{methods}{$method}{derive} = 
              $Object::Simple::CLASS_INFOS->{$mixin_class}{methods}{$method}{derive} || $mixin_class;
        }
    }
    
    # Merge accessor to caller class
    my %accessors;
    foreach my $class (@$mixin_classes, $caller_class) {
        %accessors = (%accessors, %{$Object::Simple::CLASS_INFOS->{$class}{accessors}})
            if $Object::Simple::CLASS_INFOS->{$class}{accessors};
    }
    $Object::Simple::CLASS_INFOS->{$caller_class}{accessors} = \%accessors;
}

sub mixin_method_deparse_possibility {
    my ($self, $mixin_class) = @_;
    
    # Has mixin classes
    return 1
      if ref $Object::Simple::CLASS_INFOS->{$mixin_class}{mixins} &&
         @{$Object::Simple::CLASS_INFOS->{$mixin_class}{mixins}};
    
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
    
    # Return cache if cached 
    return $Object::Simple::CLASS_INFOS->{$class}{merged_accessors}
      if $Object::Simple::CLASS_INFOS->{$class}{merged_accessors};
    
    # Get self and super classed
    my $self_and_super_classes = $UTIL->get_leftmost_isa($class);
    
    # Get merged accessor options 
    my $accessors = {};
    foreach my $class (reverse @$self_and_super_classes) {
        $accessors = {%{$accessors}, %{$Object::Simple::CLASS_INFOS->{$class}{accessors}}}
            if defined $Object::Simple::CLASS_INFOS->{$class}{accessors};
    }
    
    # Cached
    $Object::Simple::CLASS_INFOS->{$class}{merged_accessors} = $accessors;
    
    return $accessors;
}

# Create constructor
sub create_constructor {
    my ($self, $class) = @_;
    
    # Get merged accessors
    my $accessors = $UTIL->merge_self_and_super_accessors($class);
    my $object_accessors = {};
    my $translate_accessors = {};
    
    # Attr or Transalte
    foreach my $accessor (keys %$accessors) {
        my $accessor_type = $accessors->{$accessor}{type} || '';
        if ($accessor_type eq 'Attr' || $accessor_type eq 'ClassObjectAttr') {
            $object_accessors->{$accessor} = $accessors->{$accessor};
        }
        elsif ($accessor_type eq 'Translate') {
            $translate_accessors->{$accessor} = $accessors->{$accessor};
        }
    }
    
    # Create instance
    my $code =  qq/package Object::Simple::Constructor::${class};\n/ .
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
                qq/    \$self->{'$accessor_name'} = \$Object::Simple::CLASS_INFOS->{'$class'}{merged_accessors}{'$accessor_name'}{options}{convert}->(\$self->{'$accessor_name'})\n/ .
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
            qq/    \$Object::Simple::CLASS_INFOS->{'$class'}{merged_accessors}{'$accessor_name'}{options}{trigger}->(\$self) if exists \$self->{'$accessor_name'};\n/;
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

# Create accessor.
sub create_accessor {
    
    my ($self, $class, $accessor_name, $accessor_type) = @_;
    
    # Get accessor options
    my ($build, $auto_build, $read_only, $weak, $type, $convert, $deref, $trigger, $initialize)
      = @{$Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}{options}}{
            qw/build auto_build read_only weak type convert deref trigger initialize/
        };
    
    # chained
    my $chained =   exists $Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}{options}{chained}
                  ? $Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}{options}{chained}
                  : 1;
    
    # Passed value expression
    my $value = '$_[0]';
    
    # Check type
    croak("'type' option must be 'array' or 'hash' (${class}::$accessor_name)")
      if $type && !$VALID_VARIABLE_TYPE{$type};
    
    # Check deref
    croak("'deref' option must be specified with 'type' option (${class}::$accessor_name)")
      if $deref && !$type;
    
    # Beginning of accessor source code
    my $code =  qq/{\n/ .
                qq/    my \$self = shift;\n/;
    
    # Variable to strage
    my $strage;
    if ($accessor_type eq 'ClassAttr') {
        # Strage package Varialbe in case class accessor
        $strage = "\$Object::Simple::CLASS_INFOS->{\$self}{class_attrs}{'$accessor_name'}";
        $code .=
                qq/    Carp::croak("${class}::$accessor_name must be called from class, not instance")\n/ .
                qq/      if ref \$self;\n/;
    }
    else {
        # Strage hash in case normal accessor
        $strage = "\$self->{'$accessor_name'}";
    }
    
    # Create temporary variable if there is type or convert option
    $code .=    qq/    my \$value;\n/ if $type || $convert;
    
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
        
        $code .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        $UTIL->initialize_class_object_attr(\n/ .
                qq/            \$self,\n/ .
                qq/            '$accessor_name',\n/ .
                qq/            \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{initialize}\n/ .
                qq/        );\n/ .
                qq/    }\n/;
    }
    elsif ($auto_build){
        $code .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/;
        
        if(ref $auto_build eq 'CODE') {
            $code .=
                qq/        \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{auto_build}->(\$self);\n/;
        }
        else {
            my $build_method;
            if( $accessor_name =~ s/^(_*)// ){
                $build_method = $1 . "build_$accessor_name";
            }
            
            $code .=
                qq/        \$self->$build_method;\n/;
        }
        
        $code .=
                qq/    }\n/;
    }
    elsif ($build) {
        
        # Invalid 'build' option
        croak "'build' option must be scalar or code ref (${class}::$accessor_name)"
          unless !ref $build || ref $build eq 'CODE';
        
        # Build
        $code .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/ .
                qq/        \$self->$accessor_name(\n/;
        
        # Code ref
        if (ref $build) {
            $code .=
                qq/            scalar \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{build}->(\$self)\n/;
        }
        
        # Scalar
        else {
            $code .=
                qq/            scalar \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{build}\n/;
        }
        
        # Close
        $code .=
                qq/        )\n/ .
                qq/    }\n/;
    }
    
    # Read only accesor
    if ($read_only){
        $code .=
                qq/    Carp::croak("${class}::$accessor_name is read only") if \@_ > 0;\n/;
    }
    
    # Read and write accessor
    else {
        $code .=
                qq/    if(\@_ > 0) {\n/;
        
        # Variable type
        if($type) {
            if($type eq 'array') {
                $code .=
                qq/        \$value = ref \$_[0] eq 'ARRAY' ? \$_[0] : !defined \$_[0] ? undef : [\@_];\n/;
            }
            else {
                $code .=
                qq/        \$value = ref \$_[0] eq 'HASH' ? \$_[0] : !defined \$_[0] ? undef : {\@_};\n/;
            }
            $value = '$value';
        }
        
        # Convert to object;
        if ($convert) {
            if(ref $convert eq 'CODE') {
                $code .=
                qq/        \$value = \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{convert}->($value);\n/;
            }
            else {
                require Scalar::Util;
                
                $code .=
                qq/        require $convert;\n/ .
                qq/        \$value = defined $value && !Scalar::Util::blessed($value) ? $convert->new($value) : $value ;\n/;
            }
            $value = '$value';
        }
        
        # Save old value
        if ($trigger) {
            $code .=
                qq/        my \$old = $strage;\n/;
        }
        
        # Set value
        $code .=
                qq/        $strage = $value;\n/;
        
        # Weaken
        if ($weak) {
            require Scalar::Util;
            $code .=
                qq/        Scalar::Util::weaken($strage) if ref $strage;\n/;
        }
        
        # Trigger
        if ($trigger) {
            croak("'trigger' option must be code reference (${class}::$accessor_name)")
              unless ref $trigger eq 'CODE';
            
            $code .=
                qq/        \$Object::Simple::CLASS_INFOS->{'$class'}{accessors}{'$accessor_name'}{options}{trigger}->(\$self, \$old);\n/;
        }
        
        # Return self if chained
        if ($chained) {
            $code .=
                qq/        return \$self;\n/;
        }
        
        $code .=
                qq/    }\n/;
    }
    
    # Dereference
    if ($deref) {
        if ($type eq 'array') {
            $code .=
                qq/    return wantarray ? \@{$strage} : $strage;\n/;
        }
        else {
            $code .=
                qq/    return wantarray ? \%{$strage} : $strage;\n/;
        }
    }
    
    # No dereference
    else {
        $code .=
                qq/    return $strage;\n/;
    }
    
    # End of accessor source code
    $code .=    qq/}\n\n/;
    
    return $code;
}

# Create class and object hibrid accessor
sub create_class_object_accessor {
    my ($self, $class, $accessor_name) = @_;
    my $object_accessor = $UTIL->create_accessor($class, $accessor_name, 'Attr');
    $object_accessor = join("\n    ", split("\n", $object_accessor));
    
    my $class_accessor  = $UTIL->create_accessor($class, $accessor_name, 'ClassAttr');
    $class_accessor = join("\n    ", split("\n", $class_accessor));
    
    my $code = qq/{\n/ .
               qq/    my \$object_accessor = sub $object_accessor;\n\n/ .
               qq/    my \$class_accessor  = sub $class_accessor;\n\n/ .
               qq/    package $class;\n/ .
               qq/    sub $accessor_name {\n/ .
               qq/        my \$invocant = shift;\n/ .
               qq/        if (ref \$invocant) {\n/ .
               qq/            return wantarray ? (\$object_accessor->(\$invocant, \@_))\n/ .
               qq/                             : \$object_accessor->(\$invocant, \@_);\n/ .
               qq/        }\n/ .
               qq/        else {\n/ .
               qq/            return wantarray ? (\$class_accessor->(\$invocant, \@_))\n/ .
               qq/                             : \$class_accessor->(\$invocant, \@_);\n/ .
               qq/        }\n/ .
               qq/    }\n/ .
               qq/}\n\n/;
    return $code;
}

### Output accessor will be deleted in future ###
# Create accessor for output
sub create_output_accessor {
    my ($self, $class, $accessor_name) = @_;
    my $target = $Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}{options}{target};
    
    my $code =  qq/{\n/ .
                qq/    my (\$self, \$output) = \@_;\n/ .
                qq/    my \$value = \$self->$target;\n/ .
                qq/    \$\$output = \$value;\n/ .
                qq/    return \$self\n/ .
                qq/}\n\n/;
                
    return $code;
}

### Translate accessor will be deleted in future ###
# Create accessor for delegate
sub create_translate_accessor {
    my ($self, $class, $accessor_name) = @_;
    my $target = $Object::Simple::CLASS_INFOS->{$class}{accessors}{$accessor_name}{options}{target} || '';
    
    croak("${class}::$accessor_name '$target' is invalid. Translate 'target' option must be like 'method1->method2'")
      unless $target =~ /^(([a-zA-Z_][\w_]*)->)+([a-zA-Z_][\w_]*)$/;
    
    my $code =  qq/{\n/ .
                qq/    my \$self = shift;\n/ .
                qq/    if (\@_) {\n/ .
                qq/        \$self->$target(\@_);\n/ .
                qq/        return \$self;\n/ .
                qq/    }\n/ .
                qq/    return wantarray ? (\$self->$target) : \$self->$target;\n/ .
                qq/}\n\n/;
                
    return $code;
}

# Initialize ClassObjectAttr
sub initialize_class_object_attr {
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
    
    # default options
    my $default = $options->{default};
    
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


# Valid accessor options(Attr)
my %VALID_OBJECT_ACCESSOR_OPTIONS 
  = map {$_ => 1} qw(default chained weak read_only build auto_build type convert deref trigger translate extend);

# Valid class accessor options(ClassAttr)
my %VALID_CLASS_ACCESSOR_OPTIONS
  = map {$_ => 1} qw(chained weak read_only build auto_build type convert deref trigger translate extend initialize);

# Valid class accessor options(ClassAttr)
my %VALID_CLASS_OBJECT_ACCESSOR_OPTIONS
  = map {$_ => 1} qw(chained weak read_only build auto_build type convert deref trigger translate extend initialize);

### Output accessor will be deleted in future ###
# Valid class output accessor options(Output)
my %VALID_OUTPUT_OPTIONS
  = map {$_ => 1} qw(target);

### Translate accessor will be deleted in future ###
# Valid translate accessor option(Translate)
my %VALID_TRANSLATE_OPTIONS
  = map {$_ => 1} qw(target);

my $VALID_ACCESSOR_OPTIONS = {
    Attr            => \%VALID_OBJECT_ACCESSOR_OPTIONS,
    ClassAttr       => \%VALID_CLASS_ACCESSOR_OPTIONS,
    ClassObjectAttr => \%VALID_CLASS_OBJECT_ACCESSOR_OPTIONS,
    Output          => \%VALID_OUTPUT_OPTIONS,
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
my %VALID_ACCESSOR_TYPES = map {$_ => 1} qw/Attr ClassAttr ClassObjectAttr Output Translate/;
sub define_MODIFY_CODE_ATTRIBUTES {
    my ($self, $class) = @_;
    
    # MODIFY_CODE_ATTRIBUTES
    my $code = sub {
        my ($class, $code_ref, $accessor_type) = @_;
        
        # Accessor type is not exist
        croak("Accessor type '$accessor_type' is not exist. " .
              "Accessor type must be 'Attr', 'ClassAttr', " . 
              "'ClassObjectAttr'")
          unless $VALID_ACCESSOR_TYPES{$accessor_type};
        
        # Add 
        push(@Object::Simple::ACCESSOR_INFOS, [$class, $code_ref, $accessor_type]);
        
        return;
    };
    
    no strict 'refs';
    *{"${class}::MODIFY_CODE_ATTRIBUTES"} = $code;
}

package Object::Simple;

=head1 NAME
 
Object::Simple - Simple class builder
 
=head1 Version
 
Version 2.1001

=cut

our $VERSION = '2.1001';
 
=head1 Features
 
=over 4
 
=item 1. You can define accessors in very simple way.
 
=item 2. new method is prepared.
 
=item 3. You can define variouse accessor option(default, type, chained, weak)

=item 4. you can use Mixin system like Ruby
 
=back
 
If you use Object::Simple, you are free from bitter work 
writing new and accessors repeatedly.

=cut
 
=head1 Synopsis
 
    # Class definition( Book.pm )
    package Book;
    use Object::Simple;
    
    sub title  : Attr {}
    sub author : Attr {}
    sub price  : Attr {}
    
    Object::Simple->build_class; # End of module. Don't forget to call 'build_class' method
    
    # Using class
    use Book;
    my $book = Book->new(title => 'a', author => 'b', price => 1000);
    
    # Default
    sub author  : Attr { default => 'Good new' }
    sub persons : Attr { default => sub {['Ken', 'Taro']} }
    
    # Build
    sub title   : Attr { build => 'Good news' }
    sub authors : Attr { build => sub{['Ken', 'Taro']} }
    
    # Read only accessor
    sub year   : Attr { read_only => 1 }
    
    # Weak reference
    sub parent : Attr { weak => 1 }
    
    # Method chaine (default is true)
    sub title  : Attr { chained => 1 }
    
    # Variable type
    sub authors : Attr { type => 'array' }
    sub country : Attr { type => 'hash' }
    
    # Convert to object
    sub url : Attr { convert => 'URI' }
    sub url : Attr { convert => sub{ ref $_[0] ? $_[0] : URI->new($_[0]) } }
    
    # Dereference return value
    sub authors    : Attr { type => 'array', deref => 1 }
    sub country_id : Attr { type => 'hash',  deref => 1 }
    
    # Trigger when value is set
    sub error : Attr { trigger => sub{
        my $self = shift;
        $self->state('error');
    }}
    sub state : Attr {}
    
    # Define accessor for class attriute
    sub options : ClassAttr {
        type => 'array',
        auto_build => sub { shift->options([]) }
    }
    
    # Define accessor for both object attribute and class attribute
    sub options : ClassObjectAttr {
        type => 'array',
        auto_build => sub { shift->options([]) }
    }
    
    # Inheritance
    package Magazine;
    use Object::Simple(base => 'Book');
    
    # Mixin
    package Book;
    use Object::Simple( 
        mixins => [ 
            'Object::Simple::Mixin::AttrNames',
            'Object::Simple::Mixin::AttrOptions'
        ]
    );

=cut
 
=head1 Methods
 
=head2 new

Object::Simple prepare 'new' method for subclass.
So you do not have to define 'new'.
'new' can receive hash or hash reference

    $book = Book->new(title => 'Good life', author => 'Ken', price => 200);
    $book = Book->new({title => 'Good life', author => 'Ken', price => 200});

You can also override 'new' for initialize or arrange of arguments.

The following is initializing sample.

    sub new {
        my $self = shift->SUPER::new(@_);
        
        $self->initialize;
        
        return $self;
    }
    
    sub initialize {
        my $self = shift;
        
        # write what you want
    }
    
The following is arange of argument sample

    sub new {
        my ($class, $title, $author) = @_;
        
        # Arrange arguments
        my $self = $class->SUPER::new(title => $title, author => $author);
        
        return $self;
    }
 
=head2 build_class

You must call build_class at end of script. Class is build completely by this method.

    Object::Simple->build_class;

The following processes is excuted.

    1. Inherit base class
    2. Include mixin classes
    3. Create accessors
    4. Create constructor

You can specify class name if you need.

    Object::Simple->build_class($class);

=head2 class_attrs

Get class attributes

    $class_attrs = $class->class_attrs;
    
If you want to delete class attribute or check existents of class attribute
You can use this method

    delete $class->class_attrs->{title};
    exists $class->class_attrs->{title};

=head2 call_super

Call method of super class.

    $self->call_super('initialize');

You can call method of super class. but the method is not one of real super class.
Method is searched by using the follwoing order.

     +-------------+
   3 | BaseClass   | # real super class
     +-------------+
           |
     +-------------+
   2 | MixinClass1 |
     +-------------+
           |
     +-------------+
   1 | MixinClass2 |
     +-------------+
           |
     +-------------+
     | ThisClass   |
     +-------------+

If 'Mixin class2' has 'initialize' method, the method is called.

=head2 call_mixin

Call a method of mixined class

    $self->call_mixin('MixinClass1', 'initialize');

You can call any method of mixin class, even if method is not imported to your class

=head2 mixin_methods
    
Get all same name methods of mixin classes

    my $methods = $self->mixin_methods('initialize');

You can call all methods of mixined classes as the following way.

    foreach my $method (@$methods) {
        $self->$method();
    }
    
=head2 resist_accessor_info

You can resist accessor informations.

    Object::Simple->resist_accessor_info($class, $accessor_name, 
                                         $accessor_options, $accessor_type);

The following is arguments sample

    Object::Simple->resist_accessor_info('Book', 'title', {default => 1}, 'Attr');

This is equal to
    
    package Book;
    sub title : Attr {default => 1}

This method only resist accessor infomation.
If you want to build class, you must call 'build_class'

    Object::Simple->build_class('Book');

=head1 Accessor options
 
=head2 default
 
You can define attribute default value.
 
    sub title    : Attr {default => 'Good news'}
 
If you define default values using reference or Object,
you need wrapping it by sub{}.
 
    sub authors : Attr { default => sub{['Ken', 'Taro']} }

=head2 build

Create attribute when accessed first. Usage is almost same as 'default'.

    sub title   : Attr { build => 'Good news' }
    sub authors : Attr { build => sub{['Ken', 'Taro']} }

'build' subroutine receive $self. using other attribute, you can build this attribute.

    sub title : Attr { build => sub {
        my $self = shift;
        return Some::Module->new($self->authors);
    }}

=head2 read_only
 
You can create read only accessor
    
    sub title: Attr { read_only => 1 }
 
=head2 chained

Setter return value is self by default.
So you can do method chain.

    $book->title('aaa')->author('bbb')->...

If you do not use method chain,You do following.
 
    sub title  : Attr { chained => 0 }
    sub author : Attr { chained => 0 }

Setter retrun value is current value;

    my $current_value = $book->title('aaa');
    
=head2 weak
 
attribute value is weak reference.
 
    sub parent : Attr {weak => 1}

=head2 type

You can specify variable type( array, hash );

    # variable type
    sub authors    : Attr { type => 'array' }
    sub country_id : Attr { type => 'hash' }

If you specity 'array', arguments is automatically converted to array reference

     $book->authors('ken', 'taro'); # ('ken', 'taro') -> ['ken', 'taro']
     $book->authors('ken');         # ('ken')         -> ['ken']

If you specity 'hash', arguments is automatically converted to hash reference

     $book->country_id(Japan => 1); # (Japan => 1)    -> {Japan => 1}

=head2 convert

You can convert a non blessed scalar value to object.

    sub url : Attr { convert => 'URI' }
    
    $book->url('http://somehost'); # convert to URI->new('http://somehost')

You can also convert a scalar value using your convert function.

    sub url : Attr { convert => sub{ ref $_[0] ? $_[0] : URI->new($_[0]) } }


=head2 deref

You can derefference returned value.You must specify it with 'type' option.
    
    sub authors : Attr { type => 'array', deref => 1 }
    sub country_id : Attr { type => 'hash',  deref => 1 }

    my @authors = $book->authors;
    my %country_id = $book->country_id;
    
=head2 trigger

You can defined trigger function when value is set.

    sub error : Attr { trigger => sub{
        my ($self, $old) = @_;
        $self->state('error') if $self->error;
    }}
    sub state : Attr {}

trigger function recieve two argument.

    1. $self
    2. $old : old value

=head2 extend

You can extend super class accessor options. 
If you overwrite only default value, do the following

    package BaseClass
    use Object::Simple;
    sub authors { default => sub {['taro', 'ken']}, array => 1, deref => 1 }
    
    Object::Simple->build_class;
    
    package SomeClass
    use Object::Simple(base => 'BaseClass');
    sub authors { extend => 1, default => sub {['peter', 'miki']} }
    
    Object::Simple->build_class;

=head2 initialize

This accessor options is only used 
when accessor type is 'ClassAttr', or 'ClassObjectAttr'.

Initialize Class attribute or Object attribute

    sub method : ClassObjectAttr {
        initialize => {clone => $clone_method, default => $default_value }
    }
    
Sample

    sub constraints : ClassObjectAttr {
        initialize => {clone => 'hash', default => sub { {} } }; 
    }
    
If 'initialize' option is specified and when access this attribute,
super class value is cloned when invocant is class
and class attribute is cloned when invacant is object

'clone' option must be specified.The following is clone options

The following is clone options

    1. 'scalar'     # Normal copy
    2. 'array'      # array ref shallow copy : sub{ [@{shift}] }
    3. 'hash'       # hash ref shallow copy  : sub{ {%{shift}} }
    4. code ref     # your clone method, for exsample : 
                    #   sub { shift->clone }

Samples

    clone => 'scalar'
    clone => 'array'
    clone => 'hash'
    clone => sub { shift->clone }

'default' must be scalar or code ref

    default => 'good life' # scalar 
    default => sub {[]}  # array ref
    default => sub {{}}  # hash

=head1 Special accessors

=head2 ClassAttr - Accessor for class variable

You can also define accessor for class variable.

    sub options : ClassAttr {
        type => 'array',
        auto_build => sub { shift->options([]) }
    }

options set or get class variable, not some instance.

you can use the same accessor options as normal accessor except 'default' option.

If you define default value to class variable, you must use 'auto_build' option.

If this accessor is used subclass, it access subclass class variable, not the class it is defined. 

=head2 ClassObjectAttr - Accessor for object or class variable 

You can define object or class hibrid accessor.

If you invoke method from object, data is saved into object
    
    $obj->m1('a'); # save into object

If you invoke method from class, data is saved into class

    $class->m1('a'); # save into class

This is very useful.

=head1 Inheritance
 
    # Inheritance
    package Magazine;
    use Object::Simple( base => 'Book' );
 
Object::Simple do not support multiple inheritance because it is so complex.
 
=head1 Mixin
 
Object::Simple support mixin syntax
 
    # Mixin
    package Book;
    use Object::Simple( 
        mixins => [ 
            'Object::Simple::Mixin::AttrNames',
            'Object::Simple::Mixin::AttrOptions'
        ]
    );
 
Object::Simple mixin merge mixin class attribute.
    
    # mixin class
    package Some::Mixin;
    use Object::Simple;
    
    sub m2 : Attr {}
    
    Object::Simple->build_class;

    # using mixin class
    package Some::Class;
    use Object::Simple( mixins => [ 'Some::Mixin' ] );
    
    sub m1 : Attr {}
    
    Object::Simple->build_class;

Because Some::Mixin is mixined, Some::Class has two attribute m1 and m2.

=head1 Method searching order

Method searching order is like Ruby.

If method names is crashed, method search order is the following

1. This class

2. Mixin class2

3. Mixin class1

4. Base class

     +--------------+
   4 | Base class   |
     +--------------+
           |
     +--------------+
   3 | Mixin class1 |
     +--------------+
           |
     +--------------+
   2 | Mixin class2 |
     +--------------+
           |
     +--------------+
   1 | This class   |
     +--------------+

    #       1
    package ThisClass;
    #                       4                       3              2
    Object::Simple(base => 'BaseClass', mixins => ['MixinClass1', 'MixinClass2']);

=head1 Using your MODIFY_CODE_ATTRIBUTES subroutine
 
Object::Simple define own MODIFY_CODE_ATTRIBUTES subroutine.
If you use your MODIFY_CODE_ATTRIBUTES subroutine, do 'no Object::Simple;'
 
    package T19;
    use Object::Simple;
    
    sub m1 : Attr {}
    
    no Object::Simple; # unimport MODIFY_CODE_ATTRIBUTES
    
    # defined MODIFY_CODE_ATTRIBUTES
    sub MODIFY_CODE_ATTRIBUTES {
        my ($class, $ref, @attrs) = @_;
        # do what you want
        return;
    }
    
    sub m2 : YourAttribute {}
    
    Object::Simple->build_class;

=head1 Internal

=head2 CLASS_INFOS package variable

    $CLASS_INFOS data structure
    $class base             $base
           mixins           [$mixin1, $mixin2]
           mixin            $mixin  methods  $method
           methods          $method derive
           class_attrs
           constructor      $constructor
           
           accessors        $accessor   type     $type
                                        options  {default => $default, ..}
           
           marged_accessors $accessor   type     $type
                                        options  {default => $default, ..}

This variable structure will be change. so You shoud not access this variable.
Please only use to undarstand Object::Simple well.

=head1 Object::Simple sample

The following modules use Object::Simple. it will be Good sample.

You can create custamizable module easy way.

L<Validator::Custom>, L<DBIx::Custom>


=head1 Discoraged options and methods

The following options and methods are discuraged now.

Do not use these. This will be removed in future.

=head2 Translate accessor option

Translate accessor is discuraged now, because it is a little complex for reader

    sub attr : Translate { target => 'aaa' }

=head2 Output accessor options

Output accessor is discuraged now, because it is a little complex for reader

    sub attr : Output { target => 'aaa' }

=head2 exists_class_attr methods
    
Check existence of class attribute

    $class->exists_class_attr($attr);

This is discuraged now. instead, you write this
    
    exists $class->class_attrs->{$attr};

=head2 auto_build

'auto_build' options is now discoraged.

Instead of 'auto_build', use 'build'. 'build' is more simple than 'auto_build'.

    sub author : Attr { auto_build => sub { shift->author(Some::Module->new) } }
    
    sub author : Attr { build => sub { Some::Module->new } }

The following is original document.

When accessor is called first,a methods is called to build attribute.
 
    sub author : Attr { auto_build => 1 }
    sub build_author{
        my $self = shift;
        $self->atuhor( Person->new );
    }
 
Builder method name is build_ATTRIBUTE_NAME by default;
 
You can specify build method .
 
    sub author : Attr { auto_build => 1 }
    sub create_author{
        my $self = shift;
        $self->atuhor( Person->new );
    }

=head2 delete_class_attr methods

Delete class attribute

    $class->delete_class_attr($attr);

This is discuraged now. instead, you write this

    delete $class->class_attrs->{$attr};

=head1 Similar modules

The following is various class builders.
 
L<Class::Accessor>,L<Class::Accessor::Fast>, L<Moose>, L<Mouse>, L<Mojo::Base>

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

