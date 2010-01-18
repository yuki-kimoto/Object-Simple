package Object::Simple;
use 5.008_001;

use strict;
use warnings;
use Carp 'croak';

use Object::Simple::InternalUtil;
use Object::Simple::Util;

use constant IUtil => 'Object::Simple::InternalUtil';
use constant Util => 'Object::Simple::Util';

# Meta imformation
our $CLASS_INFOS;

# Classes which need to build
our @BUILD_NEED_CLASSES;

# Already built classes;
our %ALREADY_BUILD_CLASSES;
 
# Attribute information resisted by MODIFY_CODE_ATTRIBUTES handler
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
    IUtil->class_infos->{$caller_class}{base} = $options{base};
    
    # Regist mixin classes to meta information
    IUtil->class_infos->{$caller_class}{mixins} = $options{mixins};
    
    # Adapt strict and warnings pragma to caller class
    strict->import;
    warnings->import;
    
    # Define MODIFY_CODE_ATTRIBUTES subroutine of caller class
    IUtil->define_MODIFY_CODE_ATTRIBUTES($caller_class);
    
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
    my $class_infos = IUtil->class_infos;
    
    # Call constructor
    return $class_infos->{$class}{constructor}->($class,@_)
        if $class_infos->{$class}{constructor};
    
    # Search super class constructor if constructor is not resited
    foreach my $super_class (@{IUtil->get_leftmost_isa($class)}) {
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
    my $class_infos = IUtil->class_infos;
    
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
        IUtil->check_accessor_option($accessor_name, $class, $accessor_options,
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
        IUtil->include_mixin_classes($class)
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
                  = IUtil->get_super_accessor_options($base_class, $accessor_name);
                
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
                     ? Util->create_dual_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'ClassObjectAttr' 
                     ? Util->create_dual_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'Output' 
                     ? IUtil->create_output_accessor($class, $accessor_name, $options)
                     
                     # (Deprecated)
                     : $accessor_type eq 'Translate'
                     ? IUtil->create_translate_accessor($class, $accessor_name, $options)
                     
                     : undef;

            no strict 'refs';
            no warnings qw(redefine);
            *{"${class}::$accessor_name"} = $code;
        }
    }
    
    # Create constructor
    foreach my $class (@build_need_classes) {
        my $constructor_code = IUtil->create_constructor($class);
        
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
    my $class_infos = IUtil->class_infos;
    
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
    my $class_infos = IUtil->class_infos;
    
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
    my $class_infos = IUtil->class_infos;
    
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

sub class_attrs       { IUtil->class_attrs(@_) }
sub exists_class_attr { IUtil->exists_class_attr(@_) }
sub delete_class_attr { IUtil->delete_class_attr(@_) }

=head1 NAME
 
Object::Simple - a simple class builder
 
=head1 VERSION

Version 2.1301

=cut

our $VERSION = '2.1301';
 
=head1 FEATURES
 
=over 4
 
=item 1. You can define accessors in a very simple way.
 
=item 2. The "new()" method is already defined.
 
=item 3. You can define various accessor option (default, type, chained, weak).

=item 4. you can use a mixin system like Ruby's.
 
=back
 
By using Object::Simple, you will be exempt from the bitter work of
repeatedly writing the new() constructor and the accessors.

But now I recommend L<Object::Simple::Base> than L<Object::Simple>.

It is more Object Oriented, more simple and easier, and L<Mojo::Base> compatible.

See L<Object::Simple::Base>

=cut
 
=head1 SYNOPSIS
 
    # Class definition( Book.pm )
    package Book;
    use Object::Simple;
    
    sub title  : Attr {}
    sub author : Attr {}
    sub price  : Attr {}
    
    Object::Simple->build_class; 
    # End of module. Don't forget to call 'build_class' method
    
    # Using class
    use Book;
    my $book = Book->new(title => 'a', author => 'b', price => 1000);
    
    # Default
    sub author  : Attr { default => 'Good new' }
    sub persons : Attr { default => sub {['Ken', 'Taro']} }
    
    # Build
    sub title   : Attr { build => 'Good news' }
    sub authors : Attr { build => sub{['Ken', 'Taro']} }
    
    # Weak reference
    sub parent : Attr { weak => 1 }
    
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

Object::Simple defines a 'new' method for the subclass, so you do not need
to define 'new'. 'new' accepts a hash or a hash reference.

    $book = Book->new(title => 'Good life', author => 'Ken', price => 200);
    $book = Book->new({title => 'Good life', author => 'Ken', price => 200});

=head2 build_class

You must call build_class at the end of the package. The class will be 
completely constructed by this invocation.

    Object::Simple->build_class;

The following processes is excuted.

    1. Inherit base class
    2. Include mixin classes
    3. Create accessors
    4. Create constructor

You can specify class name if you need.

    Object::Simple->build_class($class);

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

See L<Object::Simple::Base>

=head1 Inheritance
 
    # Inheritance
    package Magazine;
    use Object::Simple(base => 'Book');
 
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
    use Object::Simple(mixins => ['Some::Mixin']);
    
    sub m1 : Attr {}
    
    Object::Simple->build_class;

Because Some::Mixin is mixined, Some::Class has two attribute m1 and m2.

=head1 Author
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develop this module at L<http://github.com/yuki-kimoto/object-simple> .

Please tell me bug if you find.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1; # End of Object::Simple

