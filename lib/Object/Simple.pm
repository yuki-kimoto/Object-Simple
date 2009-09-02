package Object::Simple;
use 5.008_001;
use strict;
use warnings;
 
require Carp;
 
our $VERSION = '2.0022';

# Meta imformation
our $META = {};

# Classes which need to build
our @BUILD_NEED_CLASSES;

# Already build class;
our %ALREADY_BUILD_CLASSES;
 
# Attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @CODE_ATTRIBUTE_INFOS;
 
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
        Carp::croak("'$key' is invalid import option ($caller_class)") unless $VALID_IMPORT_OPTIONS{$key};
    }
    
    # Resist base class to meta information
    $Object::Simple::META->{$caller_class}{base} = $options{base};
    
    # Regist mixin classes to meta information
    $Object::Simple::META->{$caller_class}{mixins} = $options{mixins};
    
    # Adapt strict and warnings pragma to caller class
    strict->import;
    warnings->import;
    
    # Define MODIFY_CODE_ATTRIBUTES subroutine of caller class
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES($caller_class);
    
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
    return $META->{$class}{constructor}->($class,@_)
        if $META->{$class}{constructor};
    
    # Search super class constructor  if constructor is not resited to meta information
    foreach my $super_class (@{Object::Simple::Functions::get_leftmost_isa($class)}) {
        if($META->{$super_class}{constructor}) {
            $META->{$class}{constructor} = $META->{$super_class}{constructor};
            return $META->{$class}{constructor}->($class,@_);
        }
    }
}
 
# Build class(create accessor, include mixin class, and create constructor)
my %VALID_BUILD_CLASS_OPTIONS = map {$_ => 1} qw(all class);
my $ATTR_OPTIONS_NAME_MAP = {
    Attr      => 'attr_options',
    ClassAttr => 'class_attr_options',
    Output    => 'output_attr_options',
    Translate => 'translate_attr_options'
};

sub build_class {
    my ($self, $options) = @_;
    
    # passed class name
    unless (ref $options) {
        $options = {class => $options};
    }
    
    # Attribute names
    my $attr_names = {};
    
    # Accessor code
    my $accessor_code = '';
    
    # Get caller class
    my $build_need_class = $options->{class} || caller;

    # check build_class options
    foreach my $key (keys %$options) {
        Carp::croak("'$key' is invalid build_class option ($build_need_class)")
            unless $VALID_BUILD_CLASS_OPTIONS{$key};
    }
    
    # Parse symbol table and create accessors code
    while (my $class_and_ref = shift @Object::Simple::CODE_ATTRIBUTE_INFOS) {
        my ($class, $ref, $accessor_type) = @$class_and_ref;
        
        # Parse symbol tabel to find code reference correspond to method names
        unless($attr_names->{$class}) {
        
            $attr_names->{$class} = {};
            
            no strict 'refs';
            foreach my $sym (values %{"${class}::"}) {
            
                next unless ref(*{$sym}{CODE}) eq 'CODE';
                
                $attr_names->{$class}{*{$sym}{CODE}} = *{$sym}{NAME};
            }
        }
        
        # Get attribute name
        my $attr = $attr_names->{$class}{$ref};
        
        # Get attr options
        my $attr_options = {$ref->()};
        
        # Check accessor option
        Object::Simple::Functions::check_accessor_option($attr, $class, $attr_options, $accessor_type);
        
        # Resist accessor option to meta imformation
        $Object::Simple::META->{$class}{$ATTR_OPTIONS_NAME_MAP->{$accessor_type}}{$attr} = $attr_options;
        
        # Create accessor source code
        if ($accessor_type eq 'Translate') {
            # Create translate accessor
            $accessor_code .= Object::Simple::Functions::create_translate_accessor($class, $attr);
        }
        elsif ($accessor_type eq 'Output') {
            # Create output accessor
            $accessor_code .= Object::Simple::Functions::create_output_accessor($class, $attr);
        }
        else {
            # Create normal accessor or class accessor
            if ($attr eq 'bookm') { $DB::single = 1 }
            $accessor_code .= Object::Simple::Functions::create_accessor($class, $attr, $accessor_type);
        }
    }
    
    # Create accessor
    if($accessor_code){
        no warnings qw(redefine);
        eval $accessor_code;
        Carp::croak("$accessor_code\n:$@") if $@;
    }
    
    # Inherit base class and Object::Simple
    my @build_need_classes;
    if ($options->{all}) {
        @build_need_classes = grep { !$ALREADY_BUILD_CLASSES{$_} } @Object::Simple::BUILD_NEED_CLASSES;
        @Object::Simple::BUILD_NEED_CLASSES = ();
    }
    else{
        @build_need_classes = ($build_need_class) unless $ALREADY_BUILD_CLASSES{$build_need_class};
    }
    
    foreach my $class (@build_need_classes) {
        # Initialize attr_options if it is not set
        $Object::Simple::META->{$class}{attr_options} = {}
            unless $Object::Simple::META->{$class}{attr_options};
        
        # inherit base class
        no strict 'refs';
        if( my $base_class = $Object::Simple::META->{$class}{base}) {
            @{"${class}::ISA"} = ();
            push @{"${class}::ISA"}, $base_class;
            Carp::croak("Base class '$base_class' is invalid class name ($class)")
                if $base_class =~ /[^\w:]/;
            
            unless($base_class->can('isa')) {
                eval "require $base_class;";
                Carp::croak("$@") if $@;
            }
        }
        
        push @{"${class}::ISA"}, 'Object::Simple';
        
        # Include mixin classes
        Object::Simple::Functions::include_mixin_classes($class)
            if $Object::Simple::META->{$class}{mixins};
    }
    
    # Create constructor
    foreach my $class (@build_need_classes) {
        my $constructor_code = Object::Simple::Functions::create_constructor($class);
        eval $constructor_code;
        Carp::croak("$constructor_code\n:$@") if $@;
        $Object::Simple::META->{$class}{constructor} = \&{"Object::Simple::Constructor::${class}::new"}
    }
    
    # resist already build class
    $ALREADY_BUILD_CLASSES{$_} = 1 foreach @build_need_classes;
    
    return 1;
}

package Object::Simple::UPPER;
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = $_[0];
    my $caller_class = caller;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;

    my $code = sub {
        my $method = shift;
        return sub {
            my $self = shift;
            my $caller_class = caller;
            my $mixin_classes = $Object::Simple::META->{$caller_class}{mixins} || [];
            foreach my $mixin_class (reverse @$mixin_classes) {
                my $full_qualified_method = "${mixin_class}::$method";
                no strict 'refs';
                return &{"$full_qualified_method"}($self, @_) if defined &{"$full_qualified_method"};
            }
            my $base_class = $caller_class;
            
            no strict 'refs';
            while($base_class = ${"${base_class}::ISA"}[0] ) {
                my $full_qualified_method = "${base_class}::$method";
                return &{"$full_qualified_method"}($self, @_) if defined &{"$full_qualified_method"};
            }
            return &{"Object::Simple::$method"}($self, @_) if defined &{"Object::Simple::$method"};
            Carp::croak("Cannot locate method '$method' via base class of $caller_class");
        }
    };
    
    no strict 'refs';
    *{"Object::Simple::UPPER::$method"} = $code->($method);
    goto &{"Object::Simple::UPPER::$method"};
}

package Object::Simple::MIXINS;
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = $_[0];
    my $caller_class = caller;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    
    my $code = sub {
       my $method = shift;
       return sub {
           my $self = shift;
           my $caller_class = caller;
           my $mixin_classes = $Object::Simple::META->{$caller_class}{mixins};
           return unless $mixin_classes;
           foreach my $mixin_class (@$mixin_classes) {
               my $full_qualified_method = "${mixin_class}::$method";
               no strict 'refs';
               &{"$full_qualified_method"}($self, @_) if defined &{"$full_qualified_method"};
           }
       }
    };
    
    no strict 'refs';
    *{"Object::Simple::MIXINS::$method"} = $code->($method);
    goto &{"Object::Simple::MIXINS::$method"};
}

package Object::Simple::Functions;

# Get leftmost self and parent classes
sub get_leftmost_isa {
    my $class = shift;
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

# Include mixin classes
sub include_mixin_classes {
    my $caller_class = shift;
    
    # Get mixin classes
    my $mixin_classes = $Object::Simple::META->{$caller_class}{mixins};
    Carp::croak("mixins must be array reference ($caller_class)") unless ref $mixin_classes eq 'ARRAY';
    
    # Mixin class attr options
    my $mixins_attr_options = {};
    
    # Include mixin classes
    no warnings 'redefine';
    foreach my $mixin_class (reverse @$mixin_classes) {
        Carp::croak("Mixin class '$mixin_class' is invalid class name ($caller_class)")
            if $mixin_class =~ /[^\w:]/;
        
        unless($mixin_class->can('isa')) {
            eval "require $mixin_class;";
            Carp::croak("$@") if $@;
        }
        
        # Import all methods
        no strict 'refs';
        foreach my $method ( keys %{"${mixin_class}::"} ) {
            next unless defined &{"${mixin_class}::$method"};
            next if defined &{"${caller_class}::$method"};
            
            *{"${caller_class}::$method"} = \&{"${mixin_class}::$method"};
        }
    }
    
    # Merge attr options to caller class
    foreach my $attr_options_name (values %$ATTR_OPTIONS_NAME_MAP) {
        my %attr_options;
        foreach my $class (@$mixin_classes, $caller_class) {
            %attr_options = ( %attr_options, %{$Object::Simple::META->{$class}{$attr_options_name}})
                if $Object::Simple::META->{$class}{$attr_options_name};
        }
        $Object::Simple::META->{$caller_class}{$attr_options_name} = \%attr_options;
    }
}
 
# Merge self and super accessor option
sub merge_self_and_super_accessor_option {
    
    my ($class, $attr_options_name) = @_;
    my $merged_attr_options_name = "merged_$attr_options_name";
    
    # Return cache if cached 
    return $Object::Simple::META->{$class}{$merged_attr_options_name}
      if $Object::Simple::META->{$class}{$merged_attr_options_name};
    
    # Get self and super classed
    my $self_and_super_classes
      = Object::Simple::Functions::get_leftmost_isa($class);
    
    # Get merged accessor options 
    my $attr_options = {};
    foreach my $class (reverse @$self_and_super_classes) {
        $attr_options = {%{$attr_options}, %{$Object::Simple::META->{$class}{$attr_options_name}}}
            if defined $Object::Simple::META->{$class}{$attr_options_name};
    }
    
    # Cached
    $Object::Simple::META->{$class}{$merged_attr_options_name} = $attr_options;
    
    return $attr_options;
}

# Create constructor
sub create_constructor {
    my $class = shift;
    
    # Get merged attr options
    my $attr_options = merge_self_and_super_accessor_option($class, 'attr_options');
    my $translate_attr_options = merge_self_and_super_accessor_option($class, 'translate_attr_options');
    
    # Create instance
    my $code =  qq/package Object::Simple::Constructor::${class};\n/ .
                qq/sub new {\n/ .
                qq/    my \$class = shift;\n/ .
                qq/    my \$self = !(\@_ % 2)           ? {\@_}       :\n/ .
                qq/               ref \$_[0] eq 'HASH' ? {\%{\$_[0]}} :\n/ .
                qq/                                     {\@_, undef};\n/ .
                qq/    bless \$self, \$class;\n/;
    
    # Attribute which have trigger option
    my @attrs_having_trigger;
    
    # Customize initialization
    foreach my $attr (keys %$attr_options) {
        
        # Convert option
        if ($attr_options->{$attr}{convert}) {
            if(ref $attr_options->{$attr}{convert} eq 'CODE') {
                $code .=
                qq/    \$self->{$attr} = \$Object::Simple::META->{'$class'}{merged_attr_options}{'$attr'}{convert}->(\$self->{$attr})\n/ .
                qq/        if exists \$self->{'$attr'};\n/;
            }
            else {
                require Scalar::Util;
                
                my $convert = $attr_options->{$attr}{convert};
                $code .=
                qq/    require $convert;\n/ .
                qq/    \$self->{$attr} = $convert->new(\$self->{$attr}) if defined \$self->{$attr} && !Scalar::Util::blessed(\$self->{$attr});\n/;
            }
        }
        
        # Default option
        if(defined $attr_options->{$attr}{default}) {
            if(ref $attr_options->{$attr}{default} eq 'CODE') {
                $code .=
                qq/    \$self->{$attr} ||= \$META->{'$class'}{merged_attr_options}{$attr}{default}->();\n/;
            }
            elsif(!ref $attr_options->{$attr}{default}) {
                $code .=
                qq/    \$self->{$attr} ||= \$META->{'$class'}{merged_attr_options}{$attr}{default};\n/;
            }
            else {
                Carp::croak("Value of 'default' option must be a code reference or constant value(${class}::$attr)");
            }
        }
        
        # Weak option
        if($attr_options->{$attr}{weak}) {
            require Scalar::Util;
            $code .=
                qq/    Scalar::Util::weaken(\$self->{'$attr'}) if ref \$self->{$attr};\n/;
        }
        
        # Regist attribute which have trigger option
        push @attrs_having_trigger, $attr
            if $attr_options->{$attr}{trigger};
    }
    
    # Trigger option
    foreach my $attr (@attrs_having_trigger) {
        $code .=
            qq/    \$Object::Simple::META->{'$class'}{merged_attr_options}{'$attr'}{trigger}->(\$self, \$self->{'$attr'}) if exists \$self->{'$attr'};\n/;
    }
    
    # Translate option
    foreach my $attr (keys %$translate_attr_options) {
        $code .=
            qq/    \$self->$attr(delete \$self->{'$attr'}) if exists \$self->{'$attr'};\n/;
    }
    
    # Return
    $code .=    qq/    return \$self;\n/ .
                qq/}\n/;
}

# Valid type
my %VALID_TYPE = map {$_ => 1} qw/array hash/;

# Create accessor.
sub create_accessor {
    
    my ($class, $attr, $accessor_type) = @_;
    
    my $attr_options = $ATTR_OPTIONS_NAME_MAP->{$accessor_type};
    
    # Get accessor options
    my ($auto_build, $read_only, $weak, $type, $convert, $deref, $trigger)
      = @{$Object::Simple::META->{$class}{$attr_options}{$attr}}{
            qw/auto_build read_only weak type convert deref trigger/
        };
    
    # chained
    my $chained =   exists $Object::Simple::META->{$class}{$attr_options}{$attr}{chained}
                  ? $Object::Simple::META->{$class}{$attr_options}{$attr}{chained}
                  : 1;
    
    # Passed value expression
    my $value = '$_[0]';
    
    # Check type
    Carp::croak("'type' option must be 'array' or 'hash' (${class}::$attr)")
        if $type && !$VALID_TYPE{$type};
    
    # Check deref
    Carp::croak("'deref' option must be specified with 'type' option (${class}::$attr)")
        if $deref && !$type;
    
    # Beginning of accessor source code
    my $code =  qq/package $class;\n/ .
                qq/sub $attr {\n/ .
                qq/    my \$self = shift;\n/;
    
    # Variable to strage
    my $strage;
    if ($accessor_type eq 'ClassAttr') {
        # Strage package Varialbe in case class accessor
        $strage = "\$Object::Simple::META->{\$self}{class_attr}{'$attr'}";
        $code .=
                qq/    Carp::croak("${class}::$attr must be called from class, not instance")\n/ .
                qq/      if ref \$self;\n/;
    }
    else {
        # Strage hash in case normal accessor
        $strage = "\$self->{'$attr'}";
    }
    
    # Create temporary variable if there is type or convert option
    $code .=    qq/    my \$value;\n/ if $type || $convert;
    
    # Automatically call build method
    if($auto_build){
        $code .=
                qq/    if(\@_ == 0 && ! exists $strage) {\n/;
        
        if(ref $auto_build eq 'CODE') {
            $code .=
                qq/        \$Object::Simple::META->{'$class'}{$attr_options}{'$attr'}{auto_build}->(\$self);\n/;
        }
        else {
            my $build_method;
            if( $attr =~ s/^(_*)// ){
                $build_method = $1 . "build_$attr";
            }
            
            $code .=
                qq/        \$self->$build_method;\n/;
        }
        
        $code .=
                qq/    }\n/;
    }
    
    # Read only accesor
    if ($read_only){
        $code .=
                qq/    if(\@_ > 0) {\n/ .
                qq/        Carp::croak("${class}::$attr is read only")\n/ .
                qq/    }\n/;
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
                qq/        \$value = \$Object::Simple::META->{'$class'}{$attr_options}{'$attr'}{convert}->($value);\n/;
            }
            else {
                require Scalar::Util;
                
                $code .=
                qq/        require $convert;\n/ .
                qq/        \$value = defined $value && !Scalar::Util::blessed($value) ? $convert->new($value) : $value ;\n/;
            }
            $value = '$value';
        }
        
        # Store argument optimized
        if (!$weak && !$chained && !$trigger) {
            $code .=
                qq/        return $strage = $value;\n/;
        }
        
        # Store argument the old way
        else {
            $code .=
                qq/        $strage = $value;\n/;
        }
        
        # Weaken
        if ($weak) {
            require Scalar::Util;
            $code .=
                qq/        Scalar::Util::weaken($strage) if ref $strage;\n/;
        }
        
        # Trigger
        if ($trigger) {
            Carp::croak("'trigger' option must be code reference (${class}::$attr)")
                unless ref $trigger eq 'CODE';
            
            $code .=
                qq/        \$Object::Simple::META->{'$class'}{$attr_options}{'$attr'}{trigger}->(\$self, $value);\n/;
        }
        
        # Return value or instance for chained/weak
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

sub create_output_accessor {
    my ($class, $attr) = @_;
    my $target = $Object::Simple::META->{$class}{output_attr_options}{$attr}{target};
    
    my $code =  qq/package $class;\n/ .
                qq/sub $attr {\n/ .
                qq/    my (\$self, \$output) = \@_;\n/ .
                qq/    my \$value = \$self->$target;\n/ .
                qq/    \$\$output = \$value;\n/ .
                qq/    return \$self\n/ .
                qq/}\n\n/;
                
    return $code;
}

sub create_translate_accessor {
    my ($class, $attr) = @_;
    my $target = $Object::Simple::META->{$class}{translate_attr_options}{$attr}{target} || '';
    
    Carp::croak("${class}::$attr '$target' is invalid. Translate 'target' option must be like 'method1->method2'")
        unless $target =~ /^(([a-zA-Z_][\w_]*)->)+([a-zA-Z_][\w_]*)$/;
    
    my $code =  qq/package $class;\n/ .
                qq/sub $attr {\n/ .
                qq/    my \$self = shift;\n/ .
                qq/    if (\@_) {\n/ .
                qq/        \$self->$target(\@_);\n/ .
                qq/        return \$self;\n/ .
                qq/    }\n/ .
                qq/    return wantarray ? (\$self->$target) : \$self->$target;\n/ .
                qq/}\n\n/;
                
    return $code;
}

# Valid accessor options(Attr)
my %VALID_ATTR_OPTIONS 
  = map {$_ => 1} qw(default chained weak read_only auto_build type convert deref trigger translate);

# Valid class accessor options(ClassAttr)
my %VALID_CLASS_ATTR_OPTIONS
  = map {$_ => 1} qw(chained weak read_only auto_build type convert deref trigger translate);

# Valid class output accessor options(Output)
my %VALID_OUTPUT_OPTIONS
  = map {$_ => 1} qw(target);
  
# Valid translate accessor option(Translate)
my %VALID_TRANSLATE_OPTIONS
  = map {$_ => 1} qw(target);

my $VALID_OPTIONS_MAP = {
    Attr      => \%VALID_ATTR_OPTIONS,
    ClassAttr => \%VALID_CLASS_ATTR_OPTIONS,
    Output    => \%VALID_OUTPUT_OPTIONS,
    Translate => \%VALID_TRANSLATE_OPTIONS
};

# Check accessor options
sub check_accessor_option {
    my ( $attr, $class, $attr_options, $accessor_type ) = @_;
    
    my $valid_options = $VALID_OPTIONS_MAP->{$accessor_type};
    
    foreach my $key ( keys %$attr_options ){
        Carp::croak("${class}::$attr '$key' is invalid accessor option.")
            unless $valid_options->{ $key };
    }
}
 
# Define MODIFY_CODE_ATTRIBUTRS subroutine
my %VALID_CODE_ATTRIBUTE_NAME = map {$_ => 1} qw(Attr ClassAttr Output Translate);
sub define_MODIFY_CODE_ATTRIBUTES {
    my $class = shift;
    
    my $code = sub {
        my ($class, $code_ref, $accessor_type) = @_;
        
        Carp::croak("'$accessor_type' is bad name. attribute must be 'Attr','ClassAttr','Output', or 'Translate'")
            unless $VALID_CODE_ATTRIBUTE_NAME{$accessor_type};
        
        push(@Object::Simple::CODE_ATTRIBUTE_INFOS, [$class, $code_ref, $accessor_type ]);
        
        return;
    };
    
    no strict 'refs';
    *{"${class}::MODIFY_CODE_ATTRIBUTES"} = $code;
}


=head1 NAME
 
Object::Simple - Light Weight Minimal Object System
 
=head1 VERSION
 
Version 2.0020
 
=head1 FEATURES
 
=over 4
 
=item 1. You can define accessors in very simple way.
 
=item 2. new method is prepared.
 
=item 3. You can define variouse accessor option(default, type, chained, weak)

=item 4. you can use Mixin system like Ruby
 
=back
 
If you use Object::Simple, you are free from bitter work 
writing new and accessors repeatedly.

=cut
 
=head1 SYNOPSIS
 
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
    
    # Default value
    sub author : Attr { default => 'Kimoto' }
    
    #Automatically build
    sub author : Attr { auto_build => 1 }
    sub build_author{ 
        my $self = shift;
        $self->author( $self->title . "b" );
    }
    
    # Read only accessor
    sub year : Attr { read_only => 1 }
    
    # weak reference
    sub parent : Attr { weak => 1 }
    
    # method chaine
    sub title : Attr { chained => 1 }
    
    # variable type
    sub authors : Attr { type => 'array' }
    sub country : Attr { type => 'hash' }
    
    # convert to object
    sub url : Attr { convert => 'URI' }
    sub url : Attr { convert => sub{ ref $_[0] ? $_[0] : URI->new($_[0]) } }
    
    # derefference of returned value
    sub authors    : Attr { type => 'array', deref => 1 }
    sub country_id : Attr { type => 'hash',  deref => 1 }
    
    # trigger option
    sub error : Attr { trigger => sub{ $_[0]->state('error') } }
    sub state : Attr {}
    
    # define accessor for class variable
    sub options : ClassAttr {
        type => 'array',
        auto_build => sub { shift->options([]) }
    }
    
    # define translate accessor
    sub person : Attr { default => sub{ Person->new } }
    sub name   : Translate { target => 'person->name' }
    sub age    : Translate { target => 'person->age' }
    
    # define accessor to output attribute value
    sub errors    : Attr   {}
    sub errors_to : Output { target => 'errors' }
    
    # Inheritance
    package Magazine;
    use Object::Simple( base => 'Book' );
    
    # Mixin
    package Book;
    use Object::Simple( 
        mixins => [ 
            'Object::Simple::Mixin::AttrNames',
            'Object::Simple::Mixin::AttrOptions'
        ]
    );
    

=cut
 
=head1 METHODS
 
=head2 new
 
new is prepared.
 
    use Book;
    my $book = Book->new( title => 'a', author => 'b', price => 1000 );
 
This new can be overided.
 
    # initialize object
    sub new {
        my $self = shift->SUPER::new(@_);
        
        # initialize object
        
        return $self;
    }
    
    # arrange arguments
    sub new {
        my ($self, @args) = @_;
        
        my $self = $self->SUPER::new(title => $_[0], author => $_[1]);
        
        return $self;
    }
 
=head2 build_class
 
resist attribute and create accessors.
 
Script must build_class 'Object::Simple->build_class;'
 
    Object::Simple->build_class; # End of Object::Simple!

=head1 ACCESSOR OPTIONS
 
=head2 default
 
You can define attribute default value.
 
    sub title : Attr {default => 'Good news'}
 
If you define default values using reference or Object,
you need wrapping it by sub{}.
 
    sub authors : Attr { default => sub{['Ken', 'Taro']} }
 
=head2 auto_build
 
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
    sub authors : Attr { type => 'array' }
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

    sub error : Attr { trigger => sub{ $_[0]->stete('error') } }
    sub state : Attr {}

=head1 SPECIAL ACCESSOR

=head2 ClassAttr - Accessor for class variable

You can also define accessor for class variable.

    # class attribute accessor
    sub options : ClassAttr {
        type => 'array',
        auto_build => sub { shift->options([]) }
    }

options set or get class variable, not some instance.

you can use the same accessor options as normal accessor except 'default' option.

If you define default value to class variable, you must use 'auto_build' option.

If this accessor is used subclass, it access subclass class variable, not the class it is defined. 

=head2 Output - Accessor to output attribute value

You can define accessor to output attribute value

    # define accessor to output attribute value
    sub errors    : Attr   {}
    sub errors_to : Output { target => 'errors' }
    
    sub results    : Attr   {}
    sub results_to : Output { target => 'results' }
    
This accessor is used the following way.

Create instance and Set input file and parse.
parse method save the parsed results to results attribute and  some errors to errors attribute
and continuasly get resutls to $results variable and get errors to $errors variable.
    
    use SomeParser;
    SomeParser
      ->new
      ->input_file('somefile')
      ->parse
      ->results_to(\my $results)
      ->errors_to(\my $errors)
    ;
    
You are not familiar with this style.
But this style is very beautiful and write a soruce code without duplication.
And You can get rid of typo in source code.

=head2 Translate - Accessor to convert to other accessor

You can define accessor shortcut of object of other attribute value.
    
    sub person : Attr { default => sub{ Person->new } }
    sub name   : Attr { translate => 'person->name' }
    sub age    : Attr { translate => 'person->age' }

You can accesse person->name when you call name.

=head1 INHERITANCE
 
    # Inheritance
    package Magazine;
    use Object::Simple( base => 'Book' );
 
Object::Simple do not support multiple inheritance because it is so complex.
 
=head1 MIXIN
 
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

=head1 METHODS SEARCHING ORDER

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

=head1 CALLING MIXINS METHODS

=head2 CALL ALL MIXINS METHODS

You can call all methods of mixins methods.

    $self->Object::Simple::MIXINS::initialize; # call all initialize of mixin classes
    
    $self->Object::Simple::MIXINS::DESTROY;    # call all DESTROY of mixin classes

    $self->Object::Simple::MIXINS::method;     # any method ok!

For example, you can call all initialize methods of mixin classes
    package ThisClass;
    Object::Simple(mixins => ['MixinClass1', 'MixinClass2']);
    
    sub initialize {
        my $self = shift;
        
        # call initialize of all mixin class
        $self->Object::Simple::MIXINS::initialize;
    }

=head2 CALL UPPER CLASS METHODS

You can call upper methods.
    
    $self->Object::Simple::UPPER::method;

Method is searched by the following order and call the method.

1. Mixin class2

2. Mixin class1

3. Base class

    package ThisClass;
    Object::Simple(base => 'BaseClass', mixins => ['MixinClass1', 'MixinClass2']);

    sub run {
        my $self = shift;
        $self->Object::Simple::UPPER::run;
    }

If MixinClass1 have run methods, MixinClass1::run is called.

If MIxinClass1 and MixinClass2 have run method, MixinClass2::run is called.

=head1 using your MODIFY_CODE_ATTRIBUTES subroutine
 
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

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
I develope in L<http://github.com/yuki-kimoto/>

=head1 SIMILAR MODULES
 
L<Class::Accessor>,L<Class::Accessor::Fast>, L<Moose>, L<Mouse>, L<Mojo::Base>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1; # End of Object::Simple

