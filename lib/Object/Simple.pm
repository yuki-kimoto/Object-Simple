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
my %VALID_IMPORT_OPT = map{ $_ => 1 } qw( base mixin );

# import
sub import{
    
    my ( $self, @opts ) = @_;
    
    # shortcut
    return unless $self eq 'Object::Simple';
    
    # arrange arguments
    @opts = %{ $opts[0] } if ref $opts[0] eq 'HASH';
    
    # check import option
    my $import_opt = {};
    while( my ( $opt, $val ) = splice( @opts, 0, 2 ) ){
        Carp::croak "Invalid import option '$opt'" unless $VALID_IMPORT_OPT{ $opt };
        $import_opt->{ $opt } = $val;
    }
    
    # get caller package name
    my $caller_pkg = caller;
    
    # inherit base class;
    Object::Simple::Functions::inherit_base_class( $caller_pkg, $import_opt->{ base } );
    
    # inherit Object::Simple;
    {
        no strict 'refs';
        push @{ "${caller_pkg}::ISA" }, 'Object::Simple';
    }
    
    # import methods form mixin class;
    Object::Simple::Functions::import_methods_form_mixin_classes( $caller_pkg, $import_opt->{ mixin } );
    
    # auto strict and auto warnings
    strict->import;
    warnings->import;
    
    # define MODIFY_CODE_ATTRIBUTES for caller package
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES( $caller_pkg );
    
}

# new
sub new{
    
    my $invocant = shift;
    
    # convert to class name
    my $class = ref $invocant || $invocant;
    
    # arrange arguments
    my %args = $class->_arrange_args( @_ );
    
    # create instance
    my $self = Object::Simple::Functions::create_instance( $invocant, %args );
    
    return $self;

}

# arrange arguments
sub _arrange_args{
    
    my ( $class , @args ) = @_;
    
    # arrange arguments
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    Carp::croak "key-value pairs must be passed to ${class}::new" if @args % 2;
    
    return @args;
    
}

# resist attribute infomathion at end of script
sub end{
    
    my $self = shift;
    
    # attribute names
    my $attr_names = {};
    
    # parse symbol table and create accessors
    while ( my $pkg_and_ref = shift @Object::Simple::ATTRIBUTES_INFO ) {
        
        my ($pkg, $ref ) = @$pkg_and_ref;
        
        # parse symbol tabel to find code reference correspond to method names
        unless( $attr_names->{ $pkg } ) {
        
            $attr_names->{$pkg} = {};
            
            no strict 'refs';
            foreach my $sym ( values %{"${pkg}::"} ) {
            
                next unless ref(*{$sym}{CODE}) eq 'CODE';
                
                $attr_names->{$pkg}{*{$sym}{CODE}} = *{$sym}{NAME};
                
            }
        }
        
        # get attribute name
        my $attr = $attr_names->{ $pkg }{ $ref };
        
        # get accessor option
        my $ac_opt = [ $ref->() ];
        
        # check accessor option
        Object::Simple::Functions::check_accessor_option( $attr, $pkg, @$ac_opt );
        
        # accessor option convert to hash reference
        $ac_opt = { @$ac_opt };
        
        # resist accessor option to meta imformation
        $Object::Simple::META->{ attr }{ $pkg }{ $attr } = $ac_opt;
        
        # create accessor
        {
            
            my $code = Object::Simple::Functions::create_accessor( $pkg, $attr, $ac_opt );
            no warnings qw( redefine closure );
            eval"sub ${pkg}::${attr} $code";
            
            Carp::croak( "$code: $@" ) if $@; # for debug. never ocuured.
        
        }
    }
    
    return 1;
    
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
    my ( $caller_pkg, $base ) = @_;
    
    return unless $base;
    
    Carp::croak "Invalid class name '$base'" if $base =~ /[^\w:]/;
    eval "require $base;";
    Carp::croak "$@" if $@;
    
    no strict 'refs';
    unshift @{ "${caller_pkg}::ISA" }, $base;
}

sub import_methods_form_mixin_classes{
    my ( $caller_pkg, $mixins ) = @_;
    return unless $mixins;
    # normalize mixin
    my $method_infos = get_method_infos( $mixins );
    
    # import methods
    import_methods( $caller_pkg, $method_infos );
}

# get method imformation form mixin option
sub get_method_infos{
    my $mixins = shift;
    
    $mixins = [ $mixins ] unless ref $mixins eq 'ARRAY';
    
    my $method_infos = {};
    foreach my $mixin ( @{ $mixins } ){
        
        if( ref $mixin eq 'HASH' ){
            while( my ( $mixin_pkg, $methods ) = each %{ $mixin } ){
                $methods = [ $methods ] unless ref $methods eq 'ARRAY';
                if( $method_infos->{ $mixin_pkg } ){
                    $method_infos->{ $mixin_pkg } = [ @{ $method_infos->{ $mixin_pkg } }, @{ $methods } ];
                }
                else{
                    $method_infos->{ $mixin_pkg } = $methods;
                }
            }
        }
        else{
            if( $method_infos->{ $mixin } ){
                $DB::single = 1;
                $method_infos->{ $mixin } = [ @{ $method_infos->{ $mixin } }, undef ];
            }
            else{
                $method_infos->{ $mixin } = [ undef ];
            }
        }
    }
    return $method_infos;
}

# import methods form mixin package to caller package
sub import_methods{
    my ( $caller_pkg, $mixin_info ) = @_;
    foreach my $mixin_pkg ( keys %{ $mixin_info } ){

        Carp::croak "Invalid class name '$mixin_pkg'" if $mixin_pkg =~ /[^\w:]/;
        eval "require $mixin_pkg;";
        Carp::croak "$@" if $@;

        my $methods = $mixin_info->{ $mixin_pkg };
        
        my $rename;
        ( $methods, $rename ) = expand_methods( $mixin_pkg, $methods );
        
        foreach my $method ( @{ $methods } ){
            my $renamed_method = $rename->{ $method } || $method;
            
            no strict 'refs';
            Carp::croak( "Not exsits '${mixin_pkg}::$method'" )
                unless *{ "${mixin_pkg}::$method" }{ CODE };
            
            *{ "${caller_pkg}::$renamed_method" } = \&{ "${mixin_pkg}::$method" };
        }
    }
}

# expand methods
sub expand_methods{
    my ( $mixin_pkg, $methods ) = @_;
    
    my %methods; # no dupulicate method list
    my $rename = {};
    
    foreach my $method ( @{ $methods } ){
        
        if( !defined $method ){
            no strict 'refs';
            %methods = ( %methods, map { $_ => 1 } @{ "${mixin_pkg}::EXPORT" } );
        }
        elsif( $method =~ /^:(\w+)$/ ){
            my $tag = $1;
            no strict 'refs';
            my %export_tags = %{ "${mixin_pkg}::EXPORT_TAGS" };
            Carp::croak( "Not exists :$tag in \@${mixin_pkg}::EXPORT_TAGS" )
                unless exists $export_tags{ $tag };
            
            my $methods = ${ "${mixin_pkg}::EXPORT_TAGS" }{ $tag };
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
    my ( $invocant, %args ) = @_;
    
    # bless
    my $self = {};
    my $pkg = ref $invocant || $invocant;
    bless $self, $pkg;
    
    # merge self and parent accessor option
    my $ac_opt = merge_self_and_super_accessor_option( $pkg );
    
    # initialize hash slot
    foreach my $attr ( keys %{ $ac_opt } ){
        my $arg = $args{ $attr };
        my $required = $ac_opt->{ $attr }{ required };
        
        if( $required && !defined $arg ){
            Object::Simple::Error->throw(
                type => 'attr_required',
                msg => "Attr '$attr' is required.",
                pkg => $pkg,
                attr => $attr
            );            
        }
        
        my $default = $ac_opt->{ $attr }{ default };
        
        if( defined $arg ){
            $self->$attr( $arg );
            delete $args{ $attr };
        }
        elsif( defined $default ){
            $self->{ $attr } = ref $default ? Storable::dclone( $default ) :
                                              $default;
        }
    }
    
    # attribute is no exist
    foreach my $attr ( keys %args ){
        $self->{ $attr } = $args{ $attr };
        Carp::carp( "'$attr' attribute is no exist in '$pkg' class." )
    }
    return $self;
}

# marge self and super accessor option
sub merge_self_and_super_accessor_option{
    my $pkg = shift;
    
    my @self_and_super_classes = reverse Class::ISA::self_and_super_path($pkg);
    my $ac_opt = {};
    
    foreach my $class ( @self_and_super_classes ){
        $ac_opt = { %{ $ac_opt }, %{ $Object::Simple::META->{ attr }{ $class } } }
            if defined $Object::Simple::META->{ attr }{ $class }
    }
    return $ac_opt;
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
    my ( $pkg, $attr, $ac_opt ) = @_;
    
    my $e =
            qq/{\n/ .
            # arg recieve
            qq/    my \$self = shift;\n\n/;

    if( my $auto_build = $ac_opt->{ auto_build } ){
        unless( ref $auto_build eq 'CODE' ){
            # automatically call build method
            my $build_method = $attr;
            if( $attr =~ s/^(_*)// ){
                $build_method = $1 . "build_$attr";
            }
            
            Carp::croak( "'$build_method' must exist in '$pkg' when 'auto_build' option is set." )
                unless $pkg->can( $build_method );
            
            $ac_opt->{ auto_build } = \&{ "${pkg}::${build_method}" };
        }
        
        $e .=
            qq/    if( !\@_ && ! defined \$self->{ $attr } ){\n/ .
            qq/        \$ac_opt->{ auto_build }->( \$self );\n/ .
            qq/    }\n/ .
            qq/    \n/;
    }
    
    if ( $ac_opt->{ read_only } ){
        $e .=
            qq/    if( \@_ ){\n/ .
            qq/        Object::Simple::Error->throw(\n/ .
            qq/            type => 'read_only',\n/ .
            qq/            msg => "${pkg}::$attr is read only",\n/ .
            qq/            pkg => "$pkg",\n/ .
            qq/            attr => "$attr"\n/ .
            qq/        );\n/ .
            qq/    }\n\n/;
    }
    else{
            
        $e .=
            qq/    if( \@_ ){\n/;
        
        if( my $type = $ac_opt->{ type }){
            
            if( ref $type eq 'CODE' ){
            $e .=
            qq/        my \$ret = \$ac_opt->{ type }->( \$_[0] );\n\n/;
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
            qq/                msg => "${pkg}::$attr Type error",\n/ .
            qq/                pkg => "$pkg",\n/ .
            qq/                attr => "$attr",\n/ .
            qq/                val => \$_[0]\n/ .
            qq/            );\n/ .
            qq/        }\n\n/;
        }
        
        # setter return value;
        my $setter_return = $ac_opt->{ setter_return };
        $setter_return  ||= 'undef';
        Carp::croak( "${pkg}::$attr 'setter_return' option must be 'undef', 'old', 'current', or 'self'." )
            unless $VALID_SETTER_RETURN{ $setter_return };
        
        if( $setter_return eq 'old' ){
            $e .=
            qq/        my \$old = \$self->{ $attr };\n\n/;
        }
        
        # set value
        $e .=
            qq/        \$self->{ $attr } = \$_[0];\n\n/;
        
        if( $ac_opt->{ weak } ){
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

sub define_MODIFY_CODE_ATTRIBUTES{
    my $caller_pkg = shift;
    my $e .=
        qq/package ${caller_pkg};\n/ .
        qq/sub MODIFY_CODE_ATTRIBUTES {\n/ .
        qq/\n/ .
        qq/    my (\$pkg, \$ref, \@attrs) = \@_;\n/ .
        qq/    if( \$attrs[0] eq 'Attr' ){\n/ .
        qq/        push( \@Object::Simple::ATTRIBUTES_INFO, [\$pkg, \$ref ]);\n/ .
        qq/    }\n/ .
        qq/    else{\n/ .
        qq/        die "'\$attrs[0]' is bad. attribute must be 'Attr'";\n/ .
        qq/    }\n/ .
        qq/    return;\n/ .
        qq/}\n/;
    
    eval $e;
    if( $@ ){ die "Cannot execute\n $e" }; # never occured.
}

# accessor option
my %VALID_AC_OPT 
    = map{ $_ => 1 } qw( default type read_only auto_build setter_return required weak );

# check accessor option
sub check_accessor_option{
    # accessor info
    my ( $attr, $pkg, @ac_opt ) = @_;
    
    my $hook_options_exist = {};
    while( my( $key, $val ) = splice( @ac_opt, 0, 2 ) ){
        Carp::croak "${pkg}::$attr '$key' is invalid accessor option" 
            unless $VALID_AC_OPT{ $key };
    }
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
