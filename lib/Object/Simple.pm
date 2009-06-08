package Object::Simple;
use 5.008_001;
use strict;
use warnings;
 
require Carp;
 
our $VERSION = '2.0001';
 
# meta imformation
our $META = {};
 
# attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ATTRIBUTES_INFO;
 
# valid import option value
my %VALID_IMPORT_OPTIONS = map {$_ => 1} qw(base mixins);
 
# import
sub import {
    my ($self, %options) = @_;
    
    # shortcut
    return unless $self eq 'Object::Simple';
    
    # check import option
    foreach my $key (keys %options) {
        Carp::croak("Invalid import option '$key'") unless $VALID_IMPORT_OPTIONS{$key};
    }
    
    # get caller package name
    my $caller_class = caller;
    
    # inherit base class;
    Object::Simple::Functions::inherit_base_class($caller_class, $options{base})
        if $options{base};
    
    # inherit Object::Simple;
    {
        no strict 'refs';
        push @{"${caller_class}::ISA"}, 'Object::Simple';
    }
    
    # import methods form mixin classes;
    Object::Simple::Functions::import_method_from_mixin_classes($caller_class, $options{mixins})
        if $options{mixins};
    
    # auto strict and auto warnings
    strict->import;
    warnings->import;
    
    # define MODIFY_CODE_ATTRIBUTES for caller package
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES($caller_class);
}
 
# unimport to use MODIFY_CODE_ATTRIBUTES
sub unimport {
    my $caller = caller;
    
    no strict 'refs';
    delete ${ $caller . '::' }{MODIFY_CODE_ATTRIBUTES};
}
 
# new
sub new {
    my $invocant = shift;
    
    # convert to class name
    my $class = ref $invocant || $invocant;
    
    return $META->{$class}{constructor}->($class,@_)
        if $META->{$class}{constructor};
    
    foreach my $super_class (@{Object::Simple::Functions::get_linear_isa($class)}) {
        if($META->{$super_class}{constructor}) {
            $META->{$class}{constructor} = $META->{$super_class}{constructor};
            return $META->{$class}{constructor}->($class,@_);
        }
    }
}
 
# resist attribute infomathion at end of script
sub end {
    my $self = shift;
    
    # caller class
    my $caller_class = caller;
    
    # attribute names
    my $attr_names = {};
    
    # accessor code
    my $accessor_code = '';
    
    # parse symbol table and create accessors
    while (my $class_and_ref = shift @Object::Simple::ATTRIBUTES_INFO) {
        
        my ($class, $ref) = @$class_and_ref;
        
        # parse symbol tabel to find code reference correspond to method names
        unless($attr_names->{$class}) {
        
            $attr_names->{$class} = {};
            
            no strict 'refs';
            foreach my $sym (values %{"${class}::"}) {
            
                next unless ref(*{$sym}{CODE}) eq 'CODE';
                
                $attr_names->{$class}{*{$sym}{CODE}} = *{$sym}{NAME};
            }
        }
        
        # get attribute name
        my $attr = $attr_names->{$class}{$ref};
        
        # get attr options
        my $attr_options = {$ref->()};
        
        # check accessor option
        Object::Simple::Functions::check_accessor_option($attr, $class, $attr_options);
        
        # resist accessor option to meta imformation
        $Object::Simple::META->{$class}{attr_options}{$attr} = $attr_options;
        
        # create accessor source code
        $accessor_code .= Object::Simple::Functions::create_accessor($class, $attr);
    }
    
    # create accessor
    if($accessor_code){
        no warnings qw(redefine);
        eval $accessor_code;
        Carp::croak("$accessor_code\n:$@") if $@;
    }
    
    # create constructor
    my $constructor_code = Object::Simple::Functions::create_constructor($caller_class);
    $Object::Simple::META->{$caller_class}{constructor} = eval $constructor_code;
    Carp::croak("$constructor_code\n:$@") if $@;
    
    return 1;
}
 
package Object::Simple::Functions;
 
# get self and parent classes
sub get_linear_isa {
    my $classname = shift;
    
    my @lin = ($classname);
    my %stored;
    
    no strict 'refs';
    foreach my $parent (@{"$classname\::ISA"}) {
        my $plin = get_linear_isa($parent);
        foreach (@$plin) {
            next if exists $stored{$_};
            push(@lin, $_);
            $stored{$_} = 1;
        }
    }
    return \@lin;
}
 
# inherit base class
sub inherit_base_class{
    my ($caller_class, $base) = @_;
    
    Carp::croak("Invalid class name '$base'") if $base =~ /[^\w:]/;
    eval "require $base;";
    Carp::croak("$@") if $@;
    
    no strict 'refs';
    unshift @{"${caller_class}::ISA"}, $base;
}
 
# import mixin class' methods
my %VALID_MIXIN_OPTIONS = map {$_ => 1} qw/rename select/;
sub import_method_from_mixin_classes {
    my ($caller_class, $mixin_infos) = @_;
    
    Carp::croak("mixins must be array reference.") if ref $mixin_infos ne 'ARRAY';
    
    # import methods
    foreach my $mixin_info (@$mixin_infos) {
        my $mixin_class;
        my $options = {};
        
        if (!ref $mixin_info) {
            $mixin_class = $mixin_info;
        }
        elsif (ref $mixin_info eq 'ARRAY') {
            my @options;
            ($mixin_class, @options) = @$mixin_info;
            $mixin_class ||= '';
            
            Carp::croak("mixin option must be key-value pairs.")
               if @options % 2;
            $options = {@options};
        }
        else {
            Carp::croak("mixins item must be class name or array reference. $mixin_info is bad.");
        }
        
        Carp::croak("Invalid class name '$mixin_class'") if $mixin_class =~ /[^\w:]/;
        
        eval "require $mixin_class;";
        Carp::croak($@) if $@;
        
        my $methods;
        if (my $select = $options->{select}) {
            Carp::croak("mixins select options must be array reference.")
                unless ref $select eq 'ARRAY';
            $methods = $select;
        }
        else {
            no strict 'refs';
            $methods = [@{"${mixin_class}::EXPORT"}];
        };
        
        Carp::croak("methods is not exist in \@${mixin_class}::EXPORT.")
            unless @$methods;        
        
        foreach my $option (keys %$options) {
            Carp::croak("mixin option '$option' is invalid")
                unless $VALID_MIXIN_OPTIONS{$option};
        }
        
        foreach my $method (@$methods) {
            my $rename = $options->{rename} || {};
            
            my $renamed_method = $rename->{$method} || $method;
            delete $rename->{$method};
            
            no strict 'refs';
            Carp::croak("Not exsits '${mixin_class}::$method'")
                unless *{"${mixin_class}::$method"}{CODE};
            *{"${caller_class}::$renamed_method"} = \&{"${mixin_class}::$method"};
        }
        Carp::croak("Fail $mixin_class mixin rename.") if keys %{$options->{rename}};
    }
}
 
# merge self and super accessor option
sub merge_self_and_super_accessor_option {
    
    my $class = shift;
    
    return $Object::Simple::META->{$class}{merged_attr_options}
      if $Object::Simple::META->{$class}{merged_attr_options};
    
    my $self_and_super_classes
      = Object::Simple::Functions::get_linear_isa($class);
    
    my $attr_options = {};
    
    foreach my $class (reverse @$self_and_super_classes) {
        $attr_options = {%{$attr_options}, %{$Object::Simple::META->{$class}{attr_options}}}
            if defined $Object::Simple::META->{$class}{attr_options};
    }
    
    $Object::Simple::META->{$class}{merged_attr_options} = $attr_options;
    return $attr_options;
}

# create constructor
sub create_constructor {
    my $class = shift;
    my $attr_options = merge_self_and_super_accessor_option($class);
    
    my $code =      qq/sub {\n/ .
                    qq/    my \$class = shift;\n/ .
                    qq/    my \$self = !(\@_ % 2)           ? {\@_}       :\n/ .
                    qq/               ref \$_[0] eq 'HASH' ? {\%{\$_[0]}} :\n/ .
                    qq/                                     {\@_, undef};\n/ .
                    qq/    bless \$self, \$class;\n/;
            
    foreach my $attr (keys %$attr_options) {
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
        
        if($attr_options->{$attr}{weak}) {
            require Scalar::Util;
            $code .=
                    qq/    Scalar::Util::weaken(\$self->{'$attr'}) if \$self->{$attr};\n/;
        }
    }
    
    $code .=        qq/    return \$self;\n/ .
                    qq/}\n/;
}

# create accessor.
sub create_accessor {
    
    my ($class, $attr) = @_;
    
    my ($auto_build, $read_only, $chained, $weak, $type, $convert, $deref)
      = @{$Object::Simple::META->{$class}{attr_options}{$attr}}{qw/auto_build read_only chained weak type convert deref/};
    
    my $code =  qq/sub ${class}::$attr {\n/;

    my $value;

    # argument type
    if ($type || $convert || $deref) {
        $value = '$value';
        
        if( $type ) {
            if($type eq 'array') {
                $code .=
                    qq/    my \$value = ref \$_[1] eq 'ARRAY' ? \$_[1] : [\@_[1 .. \$#_]];\n/;
            }
            elsif($type eq 'hash') {
                $code .=
                    qq/    my \$value = ref \$_[1] eq 'HASH' ? \$_[1] : {\@_[1 .. \$#_]};\n/;
            }
            else{
                Carp::croak("'type' option must be 'array' or 'hash'(${class}::$attr)"); 
            }
        }
        else{
            $code .=
                    qq/    my \$value = \$_[1];/;
        }
    }
    else {
        $value = '$_[1]';
    }
    
    # automatically call build method
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
                qq/    }\n\n/;
    }
    
    if ($read_only){
        $code .=
                qq/    if(\@_ > 1) {\n/ .
                qq/        Carp::croak("${class}::$attr is read only")\n/ .
                qq/    }\n/;
    }
    else {
        $code .=
                qq/    if(\@_ > 1) {\n/;
        
        # convert to object;
        if ($convert) {
            if (ref $convert eq 'CODE') {
                $code .=
                qq/        $value = \$Object::Simple::META->{'$class'}{attr_options}{'$attr'}{convert}->($value);\n/;
            }
            else {
                $code .=
                qq/        require $convert;\n/ .
                qq/        $value = $convert->new($value) unless eval{$value->isa('$convert')};\n/;
            }
        }
        
        # Store argument optimized
        if (!$weak && !$chained) {
            $code .=
                qq/        return \$_[0]->{'$attr'} = $value;\n/;
        }
        
        # Store argument the old way
        else {
            $code .=
                qq/        \$_[0]->{'$attr'} = $value;\n\n/;
        }
        
        # Weaken
        if ($weak) {
            require Scalar::Util;
            $code .=
                qq/        Scalar::Util::weaken(\$_[0]->{'$attr'});\n\n/;
        }
        
        # Return value or instance for chained/weak
        if ($chained) {
            $code .=
                qq/        return \$_[0];\n/;
        }

        $code .=
                qq/    }\n/;
    }
    
    # derifference
    if ($type && $deref) {
        if ($type eq 'array') {
            $code .=
                qq/    return wantarray ? \@{\$_[0]->{'$attr'}} : \$_[0]->{'$attr'};/;
        }
        elsif ($type eq 'hash') {
            $code .=
                qq/    return wantarray ? \%{\$_[0]->{'$attr'}} : \$_[0]->{'$attr'};/;
        }
    }
    else {
        $code .=
                qq/    return \$_[0]->{'$attr'};\n/;
    }
    
    $code .=    qq/}\n\n/;
    
    return $code;
}
 
# valid accessor options
my %VALID_ATTR_OPTIOTNS 
    = map {$_ => 1} qw(default chained weak read_only auto_build type convert deref);
 
# check accessor options
sub check_accessor_option {
    my ( $attr, $class, $attr_options ) = @_;
    
    foreach my $key ( keys %$attr_options ){
        Carp::croak("${class}::$attr '$key' is invalid accessor option.")
            unless $VALID_ATTR_OPTIOTNS{ $key };
    }
}
 
# define MODIFY_CODE_ATTRIBUTRS
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
 
Version 2.0001
 
=head1 FEATURES
 
=over 4
 
=item 1. You can define accessors in very simple way.
 
=item 2. new method is prepared.
 
=item 3. You can define default value of attribute.
 
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
    
    Object::Simple->end; # End of module. Don't forget to call 'end' method
    
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
 
=head2 end
 
resist attribute and create accessors.
 
Script must end 'Object::Simple->end;'
 
    Object::Simple->end; # End of Object::Simple!
 
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
 
=head1 INHERITANCE
 
    # Inheritance
    package Magazine;
    use Object::Simple( base => 'Book' );
 
Object::Simple do not support multiple inheritance because it is so dangerous.
 
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
 
This is nearly equel to
 
    package Book;
    use Object::Simple;
    
    use Object::Simple::Mixin::AttrNames;
    use Object::Simple::Mixin::AttrOptions;
 
Methods in @EXPORT is imported.
 
You can rename method if methods name crash.
 
    use Object::Simple( 
        mixins => [ 
            ['Some::Mixin', rename => { 'mehtod' => 'renamed_method' }]
        ]
    );
 
You can select methods if you want to import some methods 
 
    use Object::Simple( 
        mixins => [ 
            ['Some::Mixin', select => ['method1', 'method2']]
        ]
    );
 
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
    
    Object::Simple->end;
 
=head1 SEE ALSO
 
L<Object::Simple::Mixin::AttrNames> - mixin to get attribute names.
 
L<Object::Simple::Mixin::AttrOptions> - mixin to get Object::Simple attribute options.
 
L<Object::Simple::Mixin::Meta> - mixin to get Object::Simple meta information.
            
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