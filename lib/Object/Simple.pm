package Object::Simple;
use 5.008_001;
use strict;
use warnings;

require Carp;

our $VERSION = '0.0201';

# meta imformation( accessor option of each class )
our $META = {};

# attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ATTRIBUTES_INFO;

# valid import option value
my %VALID_IMPORT_OPTIONS = map{$_ => 1} qw(base mixin);

# import
sub import {
    my ($self, %options) = @_;
    
    # shortcut
    return unless $self eq 'Object::Simple';
    
    # check import option
    foreach my $key (keys %options) {
        Carp::croak("Invalid import option '$key'") unless $VALID_IMPORT_OPTIONS{ $key };
    }
    
    # get caller package name
    my $caller_class = caller;
    
    # inherit base class;
    Object::Simple::Functions::inherit_base_class($caller_class, $options{base});
    
    # inherit Object::Simple;
    {
        no strict 'refs';
        push @{"${caller_class}::ISA"}, 'Object::Simple';
    }
    
    # import methods form mixin class;
    Object::Simple::Functions::import_methods_mixin_class( $caller_class, $options{mixin});
    
    # auto strict and auto warnings
    strict->import;
    warnings->import;
    
    # define MODIFY_CODE_ATTRIBUTES for caller package
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES( $caller_class );
    
}

# new
sub new{
    my $invocant = shift;
    
    # convert to class name
    my $class = ref $invocant || $invocant;
    
    my $args;
    # arrange arguments
    if( ref $_[0] eq 'HASH' ){
        $args = {%{$_[0]}};
    }
    else{
        Carp::croak("key-value pairs must be passed to ${class}::new") if @_ % 2;
        $args = {@_};
    }

    # bless
    my $self = {};
    bless $self, $class;
    
    # merge self and parent accessor option
    my $attr_options
      = Object::Simple::Functions::merge_self_and_super_accessor_option($class);
    
    # initialize hash slot
    foreach my $attr (keys %{$attr_options}) {
        my $required = $attr_options->{$attr}{required};
        
        if($required && !exists $args->{$attr}) {
            require Object::Simple::Error;
            Object::Simple::Error->throw(
                type => 'attr_required',
                message => "Attr '$attr' is required.",
                class => $class,
                attr => $attr
            );            
        }
        
        if(exists $args->{$attr}) {
            $self->$attr($args->{$attr});
        }
        elsif(my $default = $attr_options->{$attr}{default} ){
            if(ref $default) {
                require Storable;
                $self->{$attr} = Storable::dclone($default);
            }
            else {
                $self->{$attr} = $default;
            }
        }
    }
    return $self;
}

# resist attribute infomathion at end of script
sub end{
    
    my $self = shift;
    
    # attribute names
    my $attr_names = {};
    
    # parse symbol table and create accessors
    while ( my $class_and_ref = shift @Object::Simple::ATTRIBUTES_INFO ) {
        
        my ($class, $ref ) = @$class_and_ref;
        
        # parse symbol tabel to find code reference correspond to method names
        unless( $attr_names->{ $class } ) {
        
            $attr_names->{$class} = {};
            
            no strict 'refs';
            foreach my $sym ( values %{"${class}::"} ) {
            
                next unless ref(*{$sym}{CODE}) eq 'CODE';
                
                $attr_names->{$class}{*{$sym}{CODE}} = *{$sym}{NAME};
                
            }
        }
        
        # get attribute name
        my $attr = $attr_names->{ $class }{ $ref };
        
        # get accessor option
        my $attr_options = { $ref->() };
        
        # check accessor option
        Object::Simple::Functions::check_accessor_option( $attr, $class, $attr_options );
        
        # resist accessor option to meta imformation
        $Object::Simple::META->{ attr_options }{ $class }{ $attr } = $attr_options;
        
        # create accessor
        {
            
            my $code = Object::Simple::Functions::create_accessor( $class, $attr, $attr_options );
            no warnings qw( redefine closure );
            eval"sub ${class}::${attr} $code";
            
            Carp::croak("$code: $@") if $@; # for debug. never ocuured.
        
        }
    }
    
    return 1;
    
}

# convert $@ to Object::Simple::Error
sub error{
    shift;
    
    return unless $@;
    
    my $error = $@;
    
    my $is_object_simple_error = eval{ $error->isa( 'Object::Simple::Error' ) };

    require Object::Simple::Error;
    my $error_object
        = $is_object_simple_error ? $error :
                                    Object::Simple::Error->new( message => "$error", position => '' );
    
    $@ = $error;
    return $error_object;
}

package Object::Simple::Functions;
use Object::Simple::Constraint;

# copied from Mouse
BEGIN {
    my $impl;
    if ($] >= 5.009_005) {
        require mro;
        $impl = \&mro::get_linear_isa;
    } else {
        my $loaded = do {
            local $SIG{__DIE__} = 'DEFAULT';
            eval { require MRO::Compat; 1 };
        };
        if ($loaded) {
            $impl = \&mro::get_linear_isa;
        } else {
#       VVVVV   CODE TAKEN FROM MRO::COMPAT   VVVVV
            my $code; # this recurses so it isn't pretty
            $code = sub {
                no strict 'refs';

                my $classname = shift;

                my @lin = ($classname);
                my %stored;
                foreach my $parent (@{"$classname\::ISA"}) {
                    my $plin = $code->($parent);
                    foreach (@$plin) {
                        next if exists $stored{$_};
                        push(@lin, $_);
                        $stored{$_} = 1;
                    }
                }
                return \@lin;
            };
#       ^^^^^   CODE TAKEN FROM MRO::COMPAT   ^^^^^
            $impl = $code;
        }
    }

    no strict 'refs';
    *{ __PACKAGE__ . '::get_linear_isa'} = $impl;
}

sub inherit_base_class{
    
    my ( $caller_class, $base ) = @_;
    
    return unless $base;
    
    Carp::croak("Invalid class name '$base'") if $base =~ /[^\w:]/;
    eval "require $base;";
    Carp::croak("$@") if $@;
    
    no strict 'refs';
    unshift @{ "${caller_class}::ISA" }, $base;
    
}

sub import_methods_mixin_class{
    
    my ( $caller_class, $mixins ) = @_;
    return unless $mixins;
    # normalize mixin
    my $method_infos = get_mixin_class_method_infos( $mixins );
    
    # import methods
    foreach my $mixin_class ( keys %{ $method_infos } ){

        Carp::croak("Invalid class name '$mixin_class'") if $mixin_class =~ /[^\w:]/;
        eval "require $mixin_class;";
        Carp::croak("$@") if $@;

        my $method_info = $method_infos->{ $mixin_class };
        
        my ( $methods, $rename ) = parse_mixin_class_method_info( $mixin_class, $method_info );
        
        foreach my $method ( @{ $methods } ){
            my $renamed_method = $rename->{ $method } || $method;
            
            no strict 'refs';
            Carp::croak("Not exsits '${mixin_class}::$method'")
                unless *{ "${mixin_class}::$method" }{ CODE };
            
            *{ "${caller_class}::$renamed_method" } = \&{ "${mixin_class}::$method" };
        }
    }    
}

# get method imformation form mixin option
sub get_mixin_class_method_infos{
    
    my $mixins = shift;
    
    $mixins = [ $mixins ] unless ref $mixins eq 'ARRAY';
    
    my $method_infos = {};
    foreach my $mixin ( @{ $mixins } ){
        
        if( ref $mixin eq 'HASH' ){
            while( my ( $mixin_class, $methods ) = each %{ $mixin } ){
                $methods = [ $methods ] unless ref $methods eq 'ARRAY';
                if( $method_infos->{ $mixin_class } ){
                    $method_infos->{ $mixin_class } = [ @{ $method_infos->{ $mixin_class } }, @{ $methods } ];
                }
                else{
                    $method_infos->{ $mixin_class } = $methods;
                }
            }
        }
        else{
            if( $method_infos->{ $mixin } ){
                $method_infos->{ $mixin } = [ @{ $method_infos->{ $mixin } }, undef ];
            }
            else{
                $method_infos->{ $mixin } = [ undef ];
            }
        }
    }
    return $method_infos;
    
}

# parse method info
sub parse_mixin_class_method_info{
    
    my ( $mixin_class, $methods ) = @_;
    
    my %methods; # no dupulicate method list
    my $rename = {};
    
    foreach my $method ( @{ $methods } ){
        
        if( !defined $method ){
            no strict 'refs';
            %methods = ( %methods, map { $_ => 1 } @{ "${mixin_class}::EXPORT" } );
        }
        elsif( $method =~ /^:(\w+)$/ ){
            my $tag = $1;
            no strict 'refs';
            my %export_tags = %{ "${mixin_class}::EXPORT_TAGS" };
            Carp::croak("Not exists :$tag in \@${mixin_class}::EXPORT_TAGS")
                unless exists $export_tags{ $tag };
            
            my $methods = ${ "${mixin_class}::EXPORT_TAGS" }{ $tag };
            %methods = ( %methods, map { $_ => 1 } @{ $methods } );
        }
        elsif( $method =~ /^(\w+)=>(\w+)$/ ){
            my $import_info = {};
            $method = $1;
            my $renamed_method = $2;
            
            $methods{ $method }++;
            $rename->{ $method } = $renamed_method;
        }
        else{
            $methods{ $method }++;
        }
    }
    return ( [ keys %methods ], $rename );
    
}

# marge self and super accessor option
sub merge_self_and_super_accessor_option {
    
    my $class = shift;
    
    return $Object::Simple::META->{merged_attr_options}{$class}
      if $Object::Simple::META->{merged_attr_options}{$class};
    
    my $self_and_super_classes
      = Object::Simple::Functions::get_linear_isa($class);
    my $attr_options = {};
    
    foreach my $class (reverse @$self_and_super_classes){
        $attr_options = {%{$attr_options}, %{$Object::Simple::META->{attr_options}{$class}}}
            if defined $Object::Simple::META->{attr_options}{$class};
    }
    
    $Object::Simple::META->{merged_attr_options}{$class} = $attr_options;
    return $attr_options;
}

# type constraint functions
our %TYPE_CONSTRAIMT = (

    Bool       => \&Object::Simple::Constraint::is_bool,
    Undef      => sub { !defined($_[0]) },
    Defined    => sub { defined($_[0]) },
    Value      => \&Object::Simple::Constraint::is_value,
    Num        => \&Object::Simple::Constraint::is_num,
    Int        => \&Object::Simple::Constraint::is_int,
    Str        => \&Object::Simple::Constraint::is_str,
    ClassName  => \&Object::Simple::Constraint::is_class_name,
    Ref        => sub { ref($_[0]) },

    ScalarRef  => \&Object::Simple::Constraint::is_scalar_ref,
    ArrayRef   => \&Object::Simple::Constraint::is_array_ref,
    HashRef    => \&Object::Simple::Constraint::is_hash_ref,
    CodeRef    => \&Object::Simple::Constraint::is_code_ref,
    RegexpRef  => \&Object::Simple::Constraint::is_regexp_ref,
    GlobRef    => \&Object::Simple::Constraint::is_glob_ref,
    FileHandle => \&Object::Simple::Constraint::is_file_handle,
    Object     => \&Object::Simple::Constraint::is_object
    
);

# valid setter return option values
my %VALID_SETTER_RETURN = map { $_ => 1 } qw( undef old current self );

# create accessor.
sub create_accessor{
    
    my ( $class, $attr, $attr_options ) = @_;
    
    my $e =
            qq/{\n/ .
            # arg recieve
            qq/    my \$self = shift;\n\n/;

    # automatically call build method
    if( my $auto_build = $attr_options->{ auto_build } ){
        
        $e .=
            qq/    if( !\@_ && ! defined \$self->{ $attr } ){\n/;
        
        if(ref $auto_build eq 'CODE') {
        $e .=
            qq/        \$attr_options->{ auto_build }->( \$self );\n/;
        }
        else {
            my $build_method;
            if( $attr =~ s/^(_*)// ){
                $build_method = $1 . "build_$attr";
            }
            
        $e .=
            qq/        \$self->$build_method\n;/;
        }
        
        $e .=
            qq/    }\n/ .
            qq/    \n/;
    }
    
    if ( $attr_options->{ read_only } ){
        $e .=
            qq/    if( \@_ ){\n/ .
            qq/        require Object::Simple::Error;\n/ .
            qq/        Object::Simple::Error->throw(\n/ .
            qq/            type => 'read_only',\n/ .
            qq/            message => "${class}::$attr is read only",\n/ .
            qq/            class => "$class",\n/ .
            qq/            attr => "$attr"\n/ .
            qq/        );\n/ .
            qq/    }\n\n/;
    }
    else{
            
        $e .=
            qq/    if( \@_ ){\n/;
        
        if( my $type = $attr_options->{ type }){
            
            if( ref $type eq 'CODE' ){
            $e .=
            qq/        my \$ret = \$attr_options->{ type }->( \$_[0] );\n\n/;
            }
            elsif( $Object::Simple::Functions::TYPE_CONSTRAIMT{ $type } ){
            $e .=
            qq/        my \$ret = \$Object::Simple::Functions::TYPE_CONSTRAIMT{ $type }->( \$_[0] );\n\n/;
            }
            else{
            $e .=
            qq/        my \$ret = Object::Simple::Constraint::isa( \$_[0], '$type' );\n\n/;
            }
            
            $e .=
            qq/        if( !\$ret ){\n/ .
            qq/            require Object::Simple::Error;\n/ .
            qq/            Object::Simple::Error->throw(\n/ .
            qq/                type => 'type_invalid',\n/ .
            qq/                message => "${class}::$attr Type error",\n/ .
            qq/                class => "$class",\n/ .
            qq/                attr => "$attr",\n/ .
            qq/                value => \$_[0]\n/ .
            qq/            );\n/ .
            qq/        }\n\n/;
        }
        
        # setter return value;
        my $setter_return = $attr_options->{ setter_return };
        $setter_return  ||= 'undef';
        Carp::croak("${class}::$attr 'setter_return' option must be 'undef', 'old', 'current', or 'self'.")
            unless $VALID_SETTER_RETURN{ $setter_return };
        
        if( $setter_return eq 'old' ){
            $e .=
            qq/        my \$old = \$self->{ $attr };\n\n/;
        }
        
        # set value
        $e .=
            qq/        \$self->{ $attr } = \$_[0];\n\n/;
        
        if( $attr_options->{ weak } ){
            require Scalar::Util;
            $e .=
            qq/        Scalar::Util::weaken( \$self->{ \$attr } )\n/ .
            qq/            if ref \$self->{ $attr };\n\n/;
        }
        
        # setter return value
        $e .= 
            $setter_return eq 'old'     ?
            qq/        return \$old;\n/ :
            
            $setter_return eq 'current' ? 
            qq/        return \$self->{ $attr };\n/ :
            
            $setter_return eq 'self'    ?
            qq/        return \$self;\n/ :
            
            qq/        return;\n/;
        
        $e .=
            qq/    }\n/;
    }
    
    # getter return value
    $e .=
            qq/    return \$self->{ $attr };\n/ .
            qq/}\n/;
    
    return $e;
}

# accessor option
my %VALID_ATTR_OPTIOTNS 
    = map{ $_ => 1 } qw( default type read_only auto_build setter_return required weak );

# check accessor option
sub check_accessor_option{
    
    # accessor info
    my ( $attr, $class, $attr_options ) = @_;
    
    my $hook_options_exist = {};
    foreach my $key ( keys %$attr_options ){
        Carp::croak("${class}::$attr '$key' is invalid accessor option")
            unless $VALID_ATTR_OPTIOTNS{ $key };
    }
}

sub define_MODIFY_CODE_ATTRIBUTES{
    my $class = shift;
    
    my $code = sub {
        my ($class, $ref, @attrs) = @_;
        if( $attrs[0] eq 'Attr' ){
            push( @Object::Simple::ATTRIBUTES_INFO, [$class, $ref ]);
        }
        else{
            die "'$attrs[0]' is bad. attribute must be 'Attr'";
        }
        return;
    };
    
    no strict 'refs';
    *{"${class}::MODIFY_CODE_ATTRIBUTES"} = $code;
}

=head1 NAME

Object::Simple - Very simple framework for Object Oriented Perl.

=head1 VERSION

Version 0.0201

=cut

=head1 CAUTION

Object::Simple is yet experimenta stage.

Please wait until Object::Simple will be stable.

=cut

=head1 FEATURES

Object::Simple is framework that simplify Object Oriented Perl.

The feature is that

=over 4

=item 1. You can define accessors in very simple way.

=item 2. new method is prepared.

=item 3. You can define default value of attribute.

=back

If you use Object::Simple, you are free from bitter work 
writing new methods and accessors repeatedly.

=cut

=head1 SYNOPSIS

    # Class definition( Book.pm )
    package Book;
    use Object::Simple;
    
    sub title : Attr {}
    sub author : Attr {}
    sub price : Attr {}
    
    Object::Simple->end; # End of module. Don't forget to call 'end' method
    
    # Using class
    use Book;
    my $book = Book->new( title => 'a', author => 'b', price => 1000 );
    
    # Default value of attribute
    sub author : Attr { default => 'Kimoto' }
    
    #Automatically build of attribute
    sub author : Attr { auto_build => 1 }
    sub build_author{ 
        my $self = shift;
        $self->author( $self->title . "b" );
    }
    
    # Constraint of attribute setting
    sub price : Attr { type => 'Int' }
    sub author : Attr { type => 'Person' }
    
    # Read only accessor
    sub year : Attr { read_only => 1 }
    
    # Required attributes
    sub width : Attr { required => 1 }
    
    # weak reference
    sub parent : Attr { weak => 1 }
    
    # setter retur value
    sub title : Attr { setter_return => 'old' }
    sub title : Attr { setter_return => 'current' }
    sub title : Attr { setter_return => 'self' }
    sub title : Attr { setter_return => 'undef' }
    
    # Inheritance
    package Magazine;
    use Object::Simple( base => 'Book' );
    
    # Mixin
    package Book;
    use Object::Simple( 
        mixin => [ 
            'Object::Simple::Mixin::AttrNames',
            'Object::Simple::Mixin::AttrOptions'
        ]
    );

=cut

=head1 METHODS

=head2 new

new method is prepared.

    use Book;
    my $book = Book->new( title => 'a', author => 'b', price => 1000 );

=head2 _arrange_args

This method receive hash or hash reference, and return hash ref by default.

You can override this method to arrange arguments like this.

    sub _arrange_args {
        my ($self, $x, $y ) = @_;
        return {x => $x, y => $y};
    }

This method must retrun hash ref.

=head2 _init

You can initialize object.

You can override this method

This method receive hash ref argments except attribrte by defined by Attr

    sub _init {
        my ($self, $args) = @_;
        
    }
    
=head2 error

You can get error as Object::Simple::Error object

    my $error = Object::Simple->error;

=head2 end

resist attribute and create accessors.

Script must end 'Object::Simple->end;'

    Object::Simple->end;


=head1 ACCESSOR OPTIONS

=head2 default

You can define attribute default value

    sub title : Attr {default => 'Good news'}
    sub author : Attr {default => ['Ken', 'Taro']}

=head2 auto_build

You can automaticaly set attribute value when accessor is called first.
    
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

=head2 type

You can define type of attribute value
    
    sub price: Attr {type => 'Int'} # must be integer
    sub author: Attr {type => 'Person'} # must be inherit Perlson class

list of default types

    Bool       => \&Object::Simple::Constraint::is_bool,
    Undef      => sub { !defined($_[0]) },
    Defined    => sub { defined($_[0]) },
    Value      => \&Object::Simple::Constraint::is_value,
    Num        => \&Object::Simple::Constraint::is_num,
    Int        => \&Object::Simple::Constraint::is_int,
    Str        => \&Object::Simple::Constraint::is_str,
    ClassName  => \&Object::Simple::Constraint::is_class_name,
    Ref        => sub { ref($_[0]) },

    ScalarRef  => \&Object::Simple::Constraint::is_scalar_ref,
    ArrayRef   => \&Object::Simple::Constraint::is_array_ref,
    HashRef    => \&Object::Simple::Constraint::is_hash_ref,
    CodeRef    => \&Object::Simple::Constraint::is_code_ref,
    RegexpRef  => \&Object::Simple::Constraint::is_regexp_ref,
    GlobRef    => \&Object::Simple::Constraint::is_glob_ref,
    FileHandle => \&Object::Simple::Constraint::is_file_handle,
    Object     => \&Object::Simple::Constraint::is_object

You can specify code reference

    sub price: Attr {type => sub{ $_[0] =~ /^\d+$/ }}

=head2 read_only

You can create read only accessor
    
    sub title: Attr { read_only => 1 }

=head2 setter_return

You can spesicy return value when setting value

    sub title : Attr { setter_return => 'old' }

list of setter_return option

    old
    current
    self
    undef

=head1 required

You can specify required attribute when instance is created.

    sub title : Attr {required => 1}

=head1 weak

attribute value is weak reference.

    sub parent : Attr {weak => 1}

=head1 SEE ALSO

L<Object::Simple::Constraint> - Constraint methods for Object::Simple 'type' option.

L<Object::Simple::Error> - Structured error system for Object::Simple.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

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

L<Class::Accessor>,L<Class::Accessor::Fast>, L<Moose>, L<Mouse>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Object::Simple
