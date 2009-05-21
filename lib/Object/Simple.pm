package Object::Simple;
use 5.008_001;
use strict;
use warnings;

require Carp;
require Object::Simple::Error;

our $VERSION = '0.01_01';

# meta imformation( accessor option of each class )
our $META = {};

# attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ATTRIBUTES_INFO;

# valid import option value
my %VALID_IMPORT_OPTIONS = map{ $_ => 1 } qw( base mixin );

# import
sub import{
    
    my ( $self, @opts ) = @_;
    
    # shortcut
    return unless $self eq 'Object::Simple';
    
    # arrange arguments
    @opts = %{ $opts[0] } if ref $opts[0] eq 'HASH';
    
    # check import option
    my $import_options = {};
    while( my ( $opt, $val ) = splice( @opts, 0, 2 ) ){
        Carp::croak "Invalid import option '$opt'" unless $VALID_IMPORT_OPTIONS{ $opt };
        $import_options->{ $opt } = $val;
    }
    
    # get caller package name
    my $caller_class = caller;
    
    # inherit base class;
    Object::Simple::Functions::inherit_base_class( $caller_class, $import_options->{ base } );
    
    # inherit Object::Simple;
    {
        no strict 'refs';
        push @{ "${caller_class}::ISA" }, 'Object::Simple';
    }
    
    # import methods form mixin class;
    Object::Simple::Functions::import_methods_mixin_class( $caller_class, $import_options->{ mixin } );
    
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
    
    # arrange arguments
    my $args = $class->_arrange_args( @_ );
    
    # create instance
    my $self = Object::Simple::Functions::create_instance( $invocant, $args );
    
    # initialize instance
    $self->_init( $args );
    
    return $self;

}

# arrange arguments
sub _arrange_args{
    
    my $class = shift;
    
    # arrange arguments
    if( ref $_[0] eq 'HASH' ){
         return {%{$_[0]}};
    }
    else{
        Carp::croak "key-value pairs must be passed to ${class}::new" if @_ % 2;
        return {@_};
    }
}

# initialize instance
sub _init{ }

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
        my $attr_options = [ $ref->() ];
        
        # check accessor option
        Object::Simple::Functions::check_accessor_option( $attr, $class, @$attr_options );
        
        # accessor option convert to hash reference
        $attr_options = { @$attr_options };
        
        # resist accessor option to meta imformation
        $Object::Simple::META->{ attr }{ $class }{ $attr } = $attr_options;
        
        # create accessor
        {
            
            my $code = Object::Simple::Functions::create_accessor( $class, $attr, $attr_options );
            no warnings qw( redefine closure );
            eval"sub ${class}::${attr} $code";
            
            Carp::croak( "$code: $@" ) if $@; # for debug. never ocuured.
        
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
    my $error_object
        = $is_object_simple_error ? $error :
                                    Object::Simple::Error->new( message => "$error", position => '' );
    
    $@ = $error;
    return $error_object;
}

package Object::Simple::Functions;
use strict;
use warnings;

use Object::Simple::Error;
use Scalar::Util;
use Storable;
use Class::ISA;
use Object::Simple::Constraint;

sub inherit_base_class{
    
    my ( $caller_class, $base ) = @_;
    
    return unless $base;
    
    Carp::croak "Invalid class name '$base'" if $base =~ /[^\w:]/;
    eval "require $base;";
    Carp::croak "$@" if $@;
    
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

        Carp::croak "Invalid class name '$mixin_class'" if $mixin_class =~ /[^\w:]/;
        eval "require $mixin_class;";
        Carp::croak "$@" if $@;

        my $method_info = $method_infos->{ $mixin_class };
        
        my ( $methods, $rename ) = parse_mixin_class_method_info( $mixin_class, $method_info );
        
        foreach my $method ( @{ $methods } ){
            my $renamed_method = $rename->{ $method } || $method;
            
            no strict 'refs';
            Carp::croak( "Not exsits '${mixin_class}::$method'" )
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
            Carp::croak( "Not exists :$tag in \@${mixin_class}::EXPORT_TAGS" )
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

# create instance
sub create_instance{
    
    my ( $invocant, $args ) = @_;
    
    # bless
    my $self = {};
    my $class = ref $invocant || $invocant;
    bless $self, $class;
    
    # merge self and parent accessor option
    my $attr_options = merge_self_and_super_accessor_option( $class );
    
    # initialize hash slot
    foreach my $attr ( keys %{ $attr_options } ){
        my $arg = delete $args->{ $attr };
        my $required = $attr_options->{ $attr }{ required };
        
        if( $required && !defined $arg ){
            Object::Simple::Error->throw(
                type => 'attr_required',
                message => "Attr '$attr' is required.",
                class => $class,
                attr => $attr
            );            
        }
        
        if( defined $arg ){
            $self->$attr( $arg );
        }
        elsif( my $default = $attr_options->{ $attr }{ default } ){
            
            $self->{ $attr } = ref $default ? Storable::dclone( $default ) :
                                              $default;
        }
    }
    
    return $self;
    
}

# marge self and super accessor option
sub merge_self_and_super_accessor_option{
    
    my $class = shift;
    
    my @self_and_super_classes = reverse Class::ISA::self_and_super_path($class);
    my $attr_options = {};
    
    foreach my $class ( @self_and_super_classes ){
        $attr_options = { %{ $attr_options }, %{ $Object::Simple::META->{ attr }{ $class } } }
            if defined $Object::Simple::META->{ attr }{ $class }
    }
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

    if( my $auto_build = $attr_options->{ auto_build } ){
        unless( ref $auto_build eq 'CODE' ){
            # automatically call build method
            my $build_method = $attr;
            if( $attr =~ s/^(_*)// ){
                $build_method = $1 . "build_$attr";
            }
            
            Carp::croak( "'$build_method' must exist in '$class' when 'auto_build' option is set." )
                unless $class->can( $build_method );
            
            $attr_options->{ auto_build } = \&{ "${class}::${build_method}" };
        }
        
        $e .=
            qq/    if( !\@_ && ! defined \$self->{ $attr } ){\n/ .
            qq/        \$attr_options->{ auto_build }->( \$self );\n/ .
            qq/    }\n/ .
            qq/    \n/;
    }
    
    if ( $attr_options->{ read_only } ){
        $e .=
            qq/    if( \@_ ){\n/ .
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
        Carp::croak( "${class}::$attr 'setter_return' option must be 'undef', 'old', 'current', or 'self'." )
            unless $VALID_SETTER_RETURN{ $setter_return };
        
        if( $setter_return eq 'old' ){
            $e .=
            qq/        my \$old = \$self->{ $attr };\n\n/;
        }
        
        # set value
        $e .=
            qq/        \$self->{ $attr } = \$_[0];\n\n/;
        
        if( $attr_options->{ weak } ){
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
    my ( $attr, $class, @attr_options ) = @_;
    
    my $hook_options_exist = {};
    while( my( $key, $val ) = splice( @attr_options, 0, 2 ) ){
        Carp::croak "${class}::$attr '$key' is invalid accessor option" 
            unless $VALID_ATTR_OPTIOTNS{ $key };
    }
    
}

sub define_MODIFY_CODE_ATTRIBUTES{
    
    my $caller_class = shift;
    my $e .=
        qq/package ${caller_class};\n/ .
        qq/sub MODIFY_CODE_ATTRIBUTES {\n/ .
        qq/\n/ .
        qq/    my (\$class, \$ref, \@attrs) = \@_;\n/ .
        qq/    if( \$attrs[0] eq 'Attr' ){\n/ .
        qq/        push( \@Object::Simple::ATTRIBUTES_INFO, [\$class, \$ref ]);\n/ .
        qq/    }\n/ .
        qq/    else{\n/ .
        qq/        die "'\$attrs[0]' is bad. attribute must be 'Attr'";\n/ .
        qq/    }\n/ .
        qq/    return;\n/ .
        qq/}\n/;
    
    eval $e;
    if( $@ ){ die "Cannot execute\n $e" }; # never occured.
    
}

=head1 NAME

Object::Simple - Very simple framework for Object Oriented Perl.

=head1 VERSION

Version 0.01_01

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

=item 4. Error object is thrown, when error is occured.

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
    use Object::Simple( mixin => [ 'Object::Simple::Mixin::Meta' ] );
    

=cut

=head1 METHODS

=head2 new

new method is prepared.

    use Book;
    my $book = Book->new( title => 'a', author => 'b', price => 1000 );

=head2 _arrange_args

You can override this method to arrange arguments.

=head2 end

resist attribute and create accessors.

    Object::Simple->end

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
