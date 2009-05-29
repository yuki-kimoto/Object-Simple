package Object::Simple;
use 5.008_001;
use strict;
use warnings;

require Carp;

our $VERSION = '0.0203';

# meta imformation( accessor option of each class )
our $META = {};

# attribute infomation resisted by MODIFY_CODE_ATTRIBUTES handler
our @ATTRIBUTES_INFO;

# valid import option value
my %VALID_IMPORT_OPTIONS = map{$_ => 1} qw(base mixins);

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
    if ($options{base}) {
        Object::Simple::Functions::inherit_base_class($caller_class, $options{base});
    }
    
    # inherit Object::Simple;
    {
        no strict 'refs';
        push @{"${caller_class}::ISA"}, 'Object::Simple';
    }
    
    # import methods form mixin classes;
    if($options{mixins}) {
        Object::Simple::Functions::import_method_from_mixin_classes($caller_class, $options{mixins});
    }
    
    # auto strict and auto warnings
    strict->import;
    warnings->import;
    
    # define MODIFY_CODE_ATTRIBUTES for caller package
    Object::Simple::Functions::define_MODIFY_CODE_ATTRIBUTES($caller_class);
}

# new
sub new {
    my $invocant = shift;
    
    # convert to class name
    my $class = ref $invocant || $invocant;
    
    my $args;
    # arrange arguments
    if(ref $_[0] eq 'HASH') {
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
        if(exists $args->{$attr}) {
            $self->$attr($args->{$attr});
        }
        elsif(my $default = $attr_options->{$attr}{default}) {
            if(!ref $default) {
                $self->{$attr} = $default;
            }
            elsif(ref $default eq 'CODE') {
                $self->{$attr} = $default->();
            }
            else {
                Carp::croak('Default has to be a code reference or constant value');
            }
        }
    }
    return $self;
}

# resist attribute infomathion at end of script
sub end {
    
    my $self = shift;
    
    # attribute names
    my $attr_names = {};
    
    # accessor code
    my $code = '';
    
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
        
        $code .= Object::Simple::Functions::create_accessor($class, $attr);
    }
    
    # create accessor
    {
        no warnings qw(redefine);
        eval $code;
        
        Carp::croak("$code: $@") if $@; # for debug. never ocuured.
    }
    
    return 1;
}

package Object::Simple::Functions;

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

sub inherit_base_class{
    
    my ($caller_class, $base) = @_;
    
    Carp::croak("Invalid class name '$base'") if $base =~ /[^\w:]/;
    eval "require $base;";
    Carp::croak("$@") if $@;
    
    no strict 'refs';
    unshift @{"${caller_class}::ISA"}, $base;
    
}

my %VALID_MIXIN_OPTIONS = map {$_ => 1} qw/rename/;
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
        
        my $methods = do {
            no strict 'refs';
            [@{"${mixin_class}::EXPORT"}];
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

# marge self and super accessor option
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

# create accessor.
sub create_accessor {
    
    my ($class, $attr) = @_;
    
    my ($auto_build, $read_only, $chained, $weak)
      = @{$Object::Simple::META->{$class}{attr_options}{$attr}}{qw/auto_build read_only chained weak/};
    
    my $code =  qq/sub ${class}::$attr {\n/;
    
    # automatically call build method
    if($auto_build){
        
        $code .=
                qq/    if(\@_ == 1 && ! exists \$_[0]->{'$attr'}) {\n/;
        
        if(ref $auto_build eq 'CODE') {
        $code .=
                qq/        \$Object::Simple::META->{$class}{attr_options}{$attr}{auto_build}->(\$_[0]);\n/;
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

        # Store argument optimized
        if (!$weak && !$chained) {
            $code .=
                qq/        return \$_[0]->{'$attr'} = \$_[1];\n/;
        }

        # Store argument the old way
        else {
            $code .=
                qq/        \$_[0]->{'$attr'} = \$_[1];\n\n/;
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
        elsif ($weak) {
            $code .=
                qq/        return \$_[0]->{'$attr'}\n/;
        }
        
        $code .=
                qq/    }\n/;
    }
    
    # getter return value
    $code .=    qq/    return \$_[0]->{$attr};\n/ .
                qq/}\n\n/;
    
    return $code;
}

# valid accessor options
my %VALID_ATTR_OPTIOTNS 
    = map {$_ => 1} qw(default chained weak read_only auto_build);

# check accessor options
sub check_accessor_option {
    my ( $attr, $class, $attr_options ) = @_;
    
    foreach my $key ( keys %$attr_options ){
        Carp::croak("${class}::$attr '$key' is invalid accessor option")
            unless $VALID_ATTR_OPTIOTNS{ $key };
    }
}

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

Version 0.0203

=cut

=head1 CAUTION

Object::Simple is yet experimenta stage.

Please wait until Object::Simple will be stable.

=cut

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
    
    # Read only accessor
    sub year : Attr { read_only => 1 }
    
    # weak reference
    sub parent : Attr { weak => 1 }
    
    # method chane
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

=head2 end

resist attribute and create accessors.

Script must end 'Object::Simple->end;'

    Object::Simple->end;


=head1 ACCESSOR OPTIONS

=head2 default

You can define attribute default value.

    sub title : Attr {default => 'Good news'}

If you define default values using reference or Object,
you need wrapping sub{}.

    sub authors : Attr { default => sub{['Ken', 'Taro']} }

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

Object::Simple do not support multiple inheritance because it is dangerous.

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

This is equel to

    package Book;
    use Object::Simple;
    
    use Object::Simple::Mixin::AttrNames;
    use Object::Simple::Mixin::AttrOptions;

You can rename method if methods name crash each other.

    use Object::Simple( 
        mixins => [ 
            ['Some::Mixin', rename => { 'mehtod' => 'renamed_method' }]
        ]
    );
    

=head1 SEE ALSO

L<Object::Simple::Mixin::AttrNames> - mixin attr_names method.

L<Object::Simple::Mixin::AttrOptions> - mixin attr_options method.

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

L<Class::Accessor>,L<Class::Accessor::Fast>, L<Moose>, L<Mouse>, L<Mojo::Base>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Object::Simple
