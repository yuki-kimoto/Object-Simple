package Object::Simple;
use 5.008_001;
use strict;
use warnings;
 
require Carp;
 
our $VERSION = '2.0003';

# Meta imformation
our $META = {};
 
# Attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ATTRIBUTES_INFO;
 
# Valid import option
my %VALID_IMPORT_OPTIONS = map {$_ => 1} qw(base mixins mixins_rename);

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
    
    # Inherit base class;
    Object::Simple::Functions::inherit_base_class($caller_class, $options{base})
        if $options{base};
    
    # Inherit Object::Simple;
    {
        no strict 'refs';
        push @{"${caller_class}::ISA"}, 'Object::Simple';
    }
    
    # Regist mixin classes to meta information
    $Object::Simple::META->{$caller_class}{mixins} = $options{mixins};
    
    # Regist methods which need rename to meta information
    $Object::Simple::META->{$caller_class}{mixins_rename} = $options{mixins_rename};
    
    # Adapt strict and warnings pragma to caller class
    strict->import;
    warnings->import;
    
    # Define MODIFY_CODE_ATTRIBUTES subroutine of caller class
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES($caller_class);
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
sub build_class {
    my $self = shift;
    
    # Get caller class
    my $caller_class = caller;
    
    # Attribute names
    my $attr_names = {};
    
    # Accessor code
    my $accessor_code = '';
    
    # Alias code
    my $alias_code = '';
    
    # Parse symbol table and create accessors code
    while (my $class_and_ref = shift @Object::Simple::ATTRIBUTES_INFO) {
        
        my ($class, $ref) = @$class_and_ref;
        
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
        Object::Simple::Functions::check_accessor_option($attr, $class, $attr_options);
        
        # Resist accessor option to meta imformation
        $Object::Simple::META->{$class}{attr_options}{$attr} = $attr_options;
        
        # Create alias source code if accessor option contain 'alias'
        if (my $alias = $attr_options->{alias}) {
            Carp::croak("Cannot alias ${$class}::$attr to $alias,because ${class}::$attr is not defined")
                unless defined &{"${class}::$attr"};
            $alias_code .= qq/*${class}::$attr= \\&${class}::$alias\n/;
        }
        
        # Create accessor source code
        else{
            $accessor_code .= Object::Simple::Functions::create_accessor($class, $attr);
        }
    }
    
    # Initialize attr_options if it is not set
    $Object::Simple::META->{$caller_class}{attr_options} = {}
        unless $Object::Simple::META->{$caller_class}{attr_options};
    
    # Join alias source code to accessor source code
    $accessor_code .= $alias_code;
    
    # Create accessor and alias
    if($accessor_code){
        no warnings qw(redefine);
        eval $accessor_code;
        Carp::croak("$accessor_code\n:$@") if $@;
    }
    
    # Include mixin classes
    Object::Simple::Functions::include_mixin_classes($caller_class)
        if $Object::Simple::META->{$caller_class}{mixins};
    
    # Create constructor
    my $constructor_code = Object::Simple::Functions::create_constructor($caller_class);
    $Object::Simple::META->{$caller_class}{constructor} = eval $constructor_code;
    Carp::croak("$constructor_code\n:$@") if $@;
    
    return 1;
}
 
package Object::Simple::Functions;

# Get leftmost self and parent classes
sub get_leftmost_isa {
    my $class = shift;
    my @leftmost_isa;
    
    # Sortcut
    return unless $class;
    
    no strict 'refs';
    my $leftmost_parent = $class;
    push @leftmost_isa, $leftmost_parent;
    while( $leftmost_parent = ${"${leftmost_parent}::ISA"}[0] ) {
        push @leftmost_isa, $leftmost_parent;
    }
    
    return \@leftmost_isa;
}

# Inherit base class
sub inherit_base_class{
    my ($caller_class, $base_class) = @_;
    
    Carp::croak("Base class '$base_class' is invalid class name ($caller_class)")
        if $base_class =~ /[^\w:]/;
    
    unless($base_class->can('isa')) {
        eval "require $base_class;";
        Carp::croak("$@") if $@;
    }
    
    no strict 'refs';
    @{"${caller_class}::ISA"} = ($base_class);
}

# Include mixin classes
sub include_mixin_classes {
    my $caller_class = shift;
    
    # Get mixin classes
    my $mixin_classes = $Object::Simple::META->{$caller_class}{mixins};
    Carp::croak("mixins must be array reference ($caller_class)") unless ref $mixin_classes eq 'ARRAY';
    
    # Check mixins_rename
    my $mixins_rename = $Object::Simple::META->{$caller_class}{mixins_rename} || {};
    Carp::croak("'mixins_rename' must be hash reference ($caller_class)") unless ref $mixins_rename eq 'HASH';
    
    # Mixin class attr options
    my $mixins_attr_options = {};
    
    # Method mixined to caller class
    my $mixined_methods = {};
    
    # Include mixin classes
    no strict 'refs';
    no warnings 'redefine';
    foreach my $mixin_class (@$mixin_classes) {
        Carp::croak("Mixin class '$mixin_class' is invalid class name ($caller_class)")
            if $mixin_class =~ /[^\w:]/;
        
        unless($mixin_class->can('isa')) {
            eval "require $mixin_class;";
            Carp::croak("$@") if $@;
        }
        
        # Import all methods
        foreach my $method ( keys %{"${mixin_class}::"} ) {
            next unless defined &{"${mixin_class}::$method"};
            next if $method eq 'new';
            
            my $rename = $mixins_rename->{"${mixin_class}::$method"} || $method;
            next if defined &{"${caller_class}::$rename"} && !$mixined_methods->{$rename};
            
            Carp::croak("rename '$rename' must be method_name") if $rename =~ /[^\w_]/;
            *{"${caller_class}::$rename"} = \&{"${mixin_class}::$method"};
            $mixined_methods->{$rename} = 1;
        }
        
        # Merge mixin class attr options
        if($Object::Simple::META->{$mixin_class}{attr_options}) {
            $mixins_attr_options = {
                %{$mixins_attr_options}, 
                %{$Object::Simple::META->{$mixin_class}{attr_options}}
            }
        }
    }
    
    # Merge mixin class attr options to caller class
    $Object::Simple::META->{$caller_class}{attr_options} = {
        %{$mixins_attr_options},
        %{$Object::Simple::META->{$caller_class}{attr_options}}
    }
}
 
# Merge self and super accessor option
sub merge_self_and_super_accessor_option {
    
    my $class = shift;
    
    # Return cache if cached 
    return $Object::Simple::META->{$class}{merged_attr_options}
      if $Object::Simple::META->{$class}{merged_attr_options};
    
    # Get self and super classed
    my $self_and_super_classes
      = Object::Simple::Functions::get_leftmost_isa($class);
    
    # Get merged accessor options 
    my $attr_options = {};
    foreach my $class (reverse @$self_and_super_classes) {
        $attr_options = {%{$attr_options}, %{$Object::Simple::META->{$class}{attr_options}}}
            if defined $Object::Simple::META->{$class}{attr_options};
    }
    
    # Cached
    $Object::Simple::META->{$class}{merged_attr_options} = $attr_options;
    
    return $attr_options;
}

# Create constructor
sub create_constructor {
    my $class = shift;
    
    # Get merged attr options
    my $attr_options = merge_self_and_super_accessor_option($class);
    
    # Create instance
    my $code =      qq/sub {\n/ .
                    qq/    my \$class = shift;\n/ .
                    qq/    my \$self = !(\@_ % 2)           ? {\@_}       :\n/ .
                    qq/               ref \$_[0] eq 'HASH' ? {\%{\$_[0]}} :\n/ .
                    qq/                                     {\@_, undef};\n/ .
                    qq/    bless \$self, \$class;\n/;
    
    # Customize initialization
    foreach my $attr (keys %$attr_options) {
        
        # Convert option
        if (my $convert = $attr_options->{$attr}{convert}) {
            if(ref $convert eq 'CODE') {
                $code .=
                qq/        \$self->{$attr} = \$Object::Simple::META->{'$class'}{merged_attr_options}{'$attr'}{convert}->(\$self->{$attr});\n/;
            }
            else {
                require Scalar::Util;
                
                $code .=
                qq/        require $convert;\n/ .
                qq/        \$self->{$attr} = $convert->new(\$self->{$attr}) if defined \$self->{$attr} && !Scalar::Util::blessed(\$self->{$attr});\n/;
            }
        }
        
        # Default option
        if(exists $attr_options->{$attr}{default}) {
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
                    qq/    Scalar::Util::weaken(\$self->{'$attr'}) if \$self->{$attr};\n/;
        }
    }
    
    # Return
    $code .=        qq/    return \$self;\n/ .
                    qq/}\n/;
}

# Valid type
my %VALID_TYPE = map {$_ => 1} qw/array hash/;

# Create accessor.
sub create_accessor {
    
    my ($class, $attr) = @_;
    
    # Get accessor options
    my ($auto_build, $read_only, $chained, $weak, $type, $convert, $deref)
      = @{$Object::Simple::META->{$class}{attr_options}{$attr}}{qw/auto_build read_only chained weak type convert deref/};
    
    # Passed value expression
    my $value = '$_[1]';
    
    # Check type
    Carp::croak("'type' option must be 'array' or 'hash' (${class}::$attr)")
        if $type && !$VALID_TYPE{$type};
    
    # Check deref
    Carp::croak("'deref' option must be specified with 'type' option (${class}::$attr)")
        if $deref && !$type;
    
    # Beginning of accessor source code
    my $code =  qq/sub ${class}::$attr {\n/;
    
    # Create temporary variable if there is type or convert option
    $code .=    qq/my \$value;\n/ if $type || $convert;
    
    # Automatically call build method
    if($auto_build){
        
        $code .=
                qq/    if(\@_ == 1 && ! exists \$_[0]->{'$attr'}) {\n/;
        
        if(ref $auto_build eq 'CODE') {
            $code .=
                qq/        \$Object::Simple::META->{'$class'}{attr_options}{'$attr'}{auto_build}->(\$_[0]);\n/;
        }
        else {
            my $build_method;
            if( $attr =~ s/^(_*)// ){
                $build_method = $1 . "build_$attr";
            }
            
            $code .=
                qq/        \$_[0]->$build_method\n;/;
        }
        
        $code .=
                qq/    }\n/;
    }
    
    # Read only accesor
    if ($read_only){
        $code .=
                qq/    if(\@_ > 1) {\n/ .
                qq/        Carp::croak("${class}::$attr is read only")\n/ .
                qq/    }\n/;
    }
    
    # Read and write accessor
    else {
        $code .=
                qq/    if(\@_ > 1) {\n/;
        
        # Variable type
        if($type) {
            if($type eq 'array') {
                $code .=
                qq/    \$value = ref \$_[1] eq 'ARRAY' ? \$_[1] : !defined \$_[1] ? undef : [\@_[1 .. \$#_]];\n/;
            }
            else {
                $code .=
                qq/    \$value = ref \$_[1] eq 'HASH' ? \$_[1] : !defined \$_[1] ? undef : {\@_[1 .. \$#_]};\n/;
            }
            $value = '$value';
        }
        
        # Convert to object;
        if ($convert) {
            if(ref $convert eq 'CODE') {
                $code .=
                qq/        \$value = \$Object::Simple::META->{'$class'}{attr_options}{'$attr'}{convert}->($value);\n/;
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
        if (!$weak && !$chained) {
            $code .=
                qq/        return \$_[0]->{'$attr'} = $value;\n/;
        }
        
        # Store argument the old way
        else {
            $code .=
                qq/        \$_[0]->{'$attr'} = $value;\n/;
        }
        
        # Weaken
        if ($weak) {
            require Scalar::Util;
            $code .=
                qq/        Scalar::Util::weaken(\$_[0]->{'$attr'});\n/;
        }
        
        # Return value or instance for chained/weak
        if ($chained) {
            $code .=
                qq/        return \$_[0];\n/;
        }
        
        $code .=
                qq/    }\n/;
    }
    
    # Dereference
    if ($deref) {
        if ($type eq 'array') {
            $code .=
                qq/    return wantarray ? \@{\$_[0]->{'$attr'}} : \$_[0]->{'$attr'};\n/;
        }
        else {
            $code .=
                qq/    return wantarray ? \%{\$_[0]->{'$attr'}} : \$_[0]->{'$attr'};\n/;
        }
    }
    
    # No dereference
    else {
        $code .=
                qq/    return \$_[0]->{'$attr'};\n/;
    }
    
    # End of accessor source code
    $code .=    qq/}\n\n/;
    
    return $code;
}
 
# Valid accessor options
my %VALID_ATTR_OPTIOTNS 
    = map {$_ => 1} qw(default chained weak read_only auto_build type convert deref alias);
 
# Check accessor options
sub check_accessor_option {
    my ( $attr, $class, $attr_options ) = @_;
    
    foreach my $key ( keys %$attr_options ){
        Carp::croak("${class}::$attr '$key' is invalid accessor option.")
            unless $VALID_ATTR_OPTIOTNS{ $key };
    }
}
 
# Define MODIFY_CODE_ATTRIBUTRS subroutine
sub define_MODIFY_CODE_ATTRIBUTES {
    my $class = shift;
    
    my $code = sub {
        my ($class, $ref, @attrs) = @_;
        if($attrs[0] eq 'Attr') {
            push(@Object::Simple::ATTRIBUTES_INFO, [$class, $ref ]);
        }
        else {
            Carp::croak("'$attrs[0]' is bad. attribute must be 'Attr'");
        }
        return;
    };
    
    no strict 'refs';
    *{"${class}::MODIFY_CODE_ATTRIBUTES"} = $code;
}
 
=head1 NAME
 
Object::Simple - Light Weight Minimal Object System
 
=head1 VERSION
 
Version 2.0003
 
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
    sub authors : Attr { type => 'array', deref => 1 }
    sub country_id : Attr { type => 'hash',  deref => 1 }
    
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
 
You can chain method
 
    sub title  : Attr { chained => 1 }
    sub author : Attr { chained => 1 }
    
    $book->title('aaa')->author('bbb')->...
    
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
    
=head2 alias

You can create alias of attribute.

    sub title          : Attr {}
    sub alias_of_title : Attr { alias => 'title' }

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
 
All methods is imported to Book.If a same named methods is exist, the method is overwrited by mixin method.

You can rename method if methods name crash.
 
    use Object::Simple( 
        mixins => [ 'Some::Mixin' ]
        mixins_rename => { 'Somo::Mixin::mehtod' => 'renamed_method' }
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

4. Thit class

     +------------+
   4 | Base class |
     +------------+
           |
     +------------+        +--------------+
   1 | This class |--+---3 | Mixin class1 |
     +------------+  |     +--------------+
                     |
                     |     +--------------+
                     +---2 | Mixin class2 |
                           +--------------+

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
 
=head1 SEE ALSO
 
L<Object::Simple::Mixin::AttrNames> - Mixin to get attribute names.
 
L<Object::Simple::Mixin::AttrOptions> - Mixin to get Object::Simple attribute options.
 
L<Object::Simple::Mixin::Meta> - Mixin to get Object::Simple meta information.

=head1 AUTHOR
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
I develope some module the following
 
L<http://github.com/yuki-kimoto/>
 
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-simo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object::Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
    perldoc Object::Simple
 
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object::Simple>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Object::Simple>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Object::Simple>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Object::Simple/>
 
=back
 
=head1 SIMILAR MODULES
 
L<Class::Accessor>,L<Class::Accessor::Fast>, L<Moose>, L<Mouse>, L<Mojo::Base>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
 
=cut
 
1; # End of Object::Simple