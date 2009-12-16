package Object::Simple;
use 5.008_001;

use strict;
use warnings;
use Carp 'croak';

use Object::Simple::Util;
use constant Util => 'Object::Simple::Util';

# Meta imformation
our $CLASS_INFOS = {};

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
    return unless $self eq __PACKAGE__;
    
    # Get caller class
    my $caller_class = caller;
    
    # Check import option
    foreach my $key (keys %options) {
        croak("'$key' is invalid import option ($caller_class)")
          unless $VALID_IMPORT_OPTIONS{$key};
    }
    
    # Resist base class to meta information
    Util->class_infos->{$caller_class}{base} = $options{base};
    
    # Regist mixin classes to meta information
    Util->class_infos->{$caller_class}{mixins} = $options{mixins};
    
    # Adapt strict and warnings pragma to caller class
    strict->import;
    warnings->import;
    
    # Define MODIFY_CODE_ATTRIBUTES subroutine of caller class
    Util->define_MODIFY_CODE_ATTRIBUTES($caller_class);
    
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
    
    # Class infos
    my $class_infos = Util->class_infos;
    
    # Call constructor
    return $class_infos->{$class}{constructor}->($class,@_)
        if $class_infos->{$class}{constructor};
    
    # Search super class constructor if constructor is not resited
    foreach my $super_class (@{Util->get_leftmost_isa($class)}) {
        if($class_infos->{$super_class}{constructor}) {
            $class_infos->{$class}{constructor}
              = $class_infos->{$super_class}{constructor};
            
            return $class_infos->{$class}{constructor}->($class,@_);
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
    
    # Class infos
    my $class_infos = Util->class_infos;
    
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
    while (my $accessor_info = shift @ACCESSOR_INFOS) {
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
        Util->check_accessor_option($accessor_name, $class, $accessor_options,
                                     $accessor_type);
        
        # Resist accessor type and accessor options
        @{$class_infos->{$class}{accessors}{$accessor_name}}{qw/type options/}
          = ($accessor_type, $accessor_options);
    }
    
    # Resist classes which need building
    my @build_need_classes;
    if ($options->{all}) {
        # Select build needing class
        @build_need_classes = grep {!$ALREADY_BUILD_CLASSES{$_}}
                                   @BUILD_NEED_CLASSES;
        
        # Clear BUILD_NEED_CLASSES
        @BUILD_NEED_CLASSES = ();
    }
    else{
        @build_need_classes = ($build_need_class)
          unless $ALREADY_BUILD_CLASSES{$build_need_class};
    }
    
    # Inherit base class and this package, and include mixin classes
    foreach my $class (@build_need_classes) {
        # Delete MODIFY_CODE_ATTRIBUTES
        {
            no strict 'refs';
            delete ${$class . '::'}{MODIFY_CODE_ATTRIBUTES};
        }
        
        # Inherit base class
        no strict 'refs';
        if( my $base_class = $class_infos->{$class}{base}) {
            @{"${class}::ISA"} = ();
            push @{"${class}::ISA"}, $base_class;
            
            croak("Base class '$base_class' is invalid class name ($class)")
              if $base_class =~ /[^\w:]/;
            
            unless($base_class->can('isa')) {
                eval "require $base_class;";
                croak("$@") if $@;
            }
        }
        
        # Inherit this package
        push @{"${class}::ISA"}, __PACKAGE__;
        
        # Include mixin classes
        Util->include_mixin_classes($class)
          if $class_infos->{$class}{mixins};
    }

    # Create constructor and resist accessor code
    foreach my $class (@build_need_classes) {
        my $accessors = $class_infos->{$class}{accessors};
        foreach my $accessor_name (keys %$accessors) {
            
            # Extend super class accessor options
            my $base_class = $class;
            while ($class_infos->{$base_class}{accessors}{$accessor_name}{options}{extend}) {
                my ($super_accessor_options, $accessor_found_class)
                  = Util->get_super_accessor_options($base_class, $accessor_name);
                
                delete $class_infos->{$base_class}{accessors}{$accessor_name}{options}{extend};
                
                last unless $super_accessor_options;
                
                $class_infos->{$base_class}{accessors}{$accessor_name}{options}
                  = {%{$super_accessor_options}, 
                     %{$class_infos->{$base_class}{accessors}{$accessor_name}{options}}};
                
                $base_class = $accessor_found_class;
            }
            
            my $accessor_type = $accessors->{$accessor_name}{type} || 'Attr';
            
            my $options = $class_infos->{$base_class}{accessors}{$accessor_name}{options};
            
            my $code = $accessor_type eq 'Attr'
                     ? Util->create_accessor($class, $accessor_name, $options)

                     : $accessor_type eq 'ClassAttr' 
                     ? Util->create_class_accessor($class, $accessor_name, $options)

                     : $accessor_type eq 'HybridAttr' 
                     ? Util->create_hybrid_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'ClassObjectAttr' 
                     ? Util->create_hybrid_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'Output' 
                     ? Util->create_output_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'Translate'
                     ? Util->create_translate_accessor($class, $accessor_name, $options)
                     
                     : undef;

            no strict 'refs';
            no warnings qw(redefine);
            *{"${class}::$accessor_name"} = $code;
        }
    }
    
    # Create constructor
    foreach my $class (@build_need_classes) {
        my $constructor_code = Util->create_constructor($class);
        
        eval $constructor_code;
        croak("$constructor_code\n:$@") if $@; # never occured
        
        $class_infos->{$class}{constructor}
          = \&{"Object::Simple::Constructors::${class}::new"};
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
    push @ACCESSOR_INFOS, 
         [$class, $accessor_options_, $accessor_type, $accessor_name];
}

# Call mixin method
sub call_mixin {
    my $self        = shift;
    my $mixin_class = shift || '';
    my $method      = shift || '';
    
    # Class infos
    my $class_infos = Util->class_infos;
    
    # Caller class
    my $caller_class = caller;
    
    # Method not exist
    croak(qq/"${mixin_class}::$method from $caller_class" is not exist/)
      unless $class_infos->{$caller_class}{mixin}{$mixin_class}{methods}{$method};
    
    return $class_infos->{$caller_class}{mixin}{$mixin_class}{methods}{$method}->($self, @_);
}

# Get mixin methods
sub mixin_methods {
    my $self         = shift;
    my $method       = shift || '';
    my $caller_class = caller;
    
    # Class infos
    my $class_infos = Util->class_infos;
    
    my $methods = [];
    foreach my $mixin_class (@{$class_infos->{$caller_class}{mixins}}) {
        
        push @$methods,
             $class_infos->{$caller_class}{mixin}{$mixin_class}{methods}{$method}
          if $class_infos->{$caller_class}{mixin}{$mixin_class}{methods}{$method};
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
    
    # Class info
    my $class_infos = Util->class_infos;
    
    # Call last mixin method
    my $mixin_found = $mixin_base_class ? 0 : 1;
    if ($class_infos->{$base_class}{mixins}) {
        foreach my $mixin_class (reverse @{$class_infos->{$base_class}{mixins}}) {
            if ($mixin_base_class && $mixin_base_class eq $mixin_class) {
                $mixin_found = 1;
            }
            elsif ($mixin_found && $class_infos->{$base_class}{mixin}{$mixin_class}{methods}{$method}) {
                return $class_infos->{$base_class}{mixin}{$mixin_class}{methods}{$method}->($self, @_);
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

sub class_attrs       { Util->class_attrs(@_) }
sub exists_class_attr { Util->exists_class_attr(@_) }
sub delete_class_attr { Util->delete_class_attr(@_) }

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
    sub options : ClassAttr { type => 'array',  build => sub {[]} }
    
    # Define accessor for both object attribute and class attribute
    sub options : HybridAttr { type => 'array', build => sub {[]} }
    
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

=head2 clone

This accessor options is only used 
when accessor type is 'ClassAttr', or 'HybridAttr'.

Clone Class attribute or Object attribute

    sub method : HybridAttr {
        clone => $clone_method, build => $default_value }
    }
    
Sample

    sub constraints : HibridAttr { clone => 'hash', build => sub {{}} }
    
If 'clone' option is specified and when access this attribute,
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

=head1 Special accessors

=head2 ClassAttr - Accessor for class variable

You can also define accessor for class variable.

    sub options : ClassAttr { type => 'array', build => sub {[]} }

options set or get class variable, not some instance.

you can use the same accessor options as normal accessor except 'default' option.

If you define default value to class variable, you must use 'build' option.

If this accessor is used subclass, it access subclass class variable, not the class it is defined. 

=head2 HybridAttr - Accessor for object or class variable 

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
    
=head2 initialize

is now discoraged. instead of 'initialize', use 'clone'.

The following is original document.

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

=head2 delete_class_attr methods

Delete class attribute

    $class->delete_class_attr($attr);

This is discuraged now. instead, you write this

    delete $class->class_attrs->{$attr};

=head2 ClassObjectAttr

'ClassObjectAttr' is deprecated. This is renamed to 'HybridAttr'.

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

