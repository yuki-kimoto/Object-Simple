package Object::Simple;

our $VERSION = '3.10';

use strict;
use warnings;
use Scalar::Util ();

no warnings 'redefine';

use Carp ();

my $role_refs = [];

sub import {
  my $class = shift;
  
  return unless @_;

  # Caller
  my $caller = caller;
  
  # No export syntax
  my $no_export_syntax;
  unless (grep { $_[0] eq $_ } qw/new attr class_attr dual_attr/) {
    $no_export_syntax = 1;
  }
  
  # Inheritance and including role
  if ($no_export_syntax) {
    
    # Option
    my %opt;
    my $base_opt_name;
    if (@_ % 2 != 0) {
      my $base_opt_name = shift;
      if ($base_opt_name ne '-base') {
        Carp::croak "'$base_opt_name' is invalid option(Object::Simple::import())";
      }
      $opt{-base} = undef;
    }
    %opt = (%opt, @_);
    
    # Base class
    my $base_class = delete $opt{-base};
    
    # Roles
    my $roles = delete $opt{with};
    if (defined $roles) {
      $roles = [$roles] if ref $roles ne 'ARRAY';
    }
    else {
      $roles = [];
    }
    
    # Check option
    for my $opt_name (keys %opt) {
      Carp::croak "'$opt_name' is invalid option(Object::Simple::import())";
    }
    
    # Export has function
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::has"} = sub { attr($caller, @_) };
    
    # Inheritance
    if ($base_class) {
      $base_class =~ s/::|'/\//g;
      require "$base_class.pm" unless $base_class->can('new');
      push @{"${caller}::ISA"}, $base_class;
    }
    else { push @{"${caller}::ISA"}, $class }
    
    # Roles
    for my $role (@$roles) {
      eval "require $role";
      Carp::croak $@ if $@;
      
      my $role_file = $role;
      $role_file =~ s/::/\//g;
      $role_file .= ".pm";
      
      my $role_path = $INC{$role_file};
      open my $fh, '<', $role_path
        or Carp::croak "Can't open file $role_path: $!";
      
      my $role_content = do { local $/; <$fh> };
      
      my $role_ref = \do {"$role"};
      push @$role_refs, $role_ref;
      my $role_id = Scalar::Util::refaddr $role_ref;
      my $role_for_file = "${role}::role_$role_id";
      $role_id++;
      $INC{$role_for_file} = undef;
      
      my $role_for = $role_for_file;
      $role_for =~ s/\//::/g;
      $role_for =~ s/\.pm$//;
      
      my $role_for_content = $role_content;
      $role_for_content =~ s/package\s+(.+?);/package $role_for;/;
      eval $role_for_content;
      
      {
        no strict 'refs';
        my $parent = ${"${class}::ISA"}[0];
        @{"${class}::ISA"} = ($role_for);
        if ($parent) {
          @{"${role_for}::ISA"} = ($parent);
        }
      }
      
      Carp::croak $@ if $@;
    }
    
    # strict!
    strict->import;
    warnings->import;

    # Modern!
    feature->import(':5.10') if $] >= 5.010;
  }
  
  # Export methods
  else {
    my @methods = @_;
  
    # Exports
    my %exports = map { $_ => 1 } qw/new attr class_attr dual_attr/;
    
    # Export methods
    for my $method (@methods) {
      
      # Can be Exported?
      Carp::croak("Cannot export '$method'.")
        unless $exports{$method};
      
      # Export
      no strict 'refs';
      *{"${caller}::$method"} = \&{"$method"};
    }
  }
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub attr {
  my ($self, @args) = @_;
  
  my $class = ref $self || $self;
  
  # Fix argument
  unshift @args, (shift @args, undef) if @args % 2;
  
  for (my $i = 0; $i < @args; $i += 2) {
      
    # Attribute name
    my $attrs = $args[$i];
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Default
    my $default = $args[$i + 1];
    
    for my $attr (@$attrs) {

      Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

      # Header (check arguments)
      my $code = "*{\"${class}::$attr\"} = sub {\n  if (\@_ == 1) {\n";

      # No default value (return value)
      unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

      # Default value
      else {

        Carp::croak "Default has to be a code reference or constant value (${class}::$attr)"
          if ref $default && ref $default ne 'CODE';

        # Return value
        $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

        # Return default value
        $code .= "    return \$_[0]{'$attr'} = ";
        $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
      }

      # Store value
      $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

      # Footer (return invocant)
      $code .= "  \$_[0];\n}";

      # We compile custom attribute code for speed
      no strict 'refs';
      warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{OBJECT_SIMPLE_DEBUG};
      Carp::croak "Object::Simple error: $@" unless eval "$code;1";
    }
  }
}

# DEPRECATED!
sub class_attr {
  require Object::Simple::Accessor;
  Object::Simple::Accessor::create_accessors('class_attr', @_)
}

# DEPRECATED!
sub dual_attr {
  require Object::Simple::Accessor;
  Object::Simple::Accessor::create_accessors('dual_attr', @_)
}

=head1 NAME

Object::Simple - Simple class builder(Mojo::Base porting)

=head1 SYNOPSIS

  package SomeClass;
  use Object::Simple -base;
  
  # Create a accessor
  has 'foo';
  
  # Create a accessor having default value
  has foo => 1;
  has foo => sub { [] };
  has foo => sub { {} };
  has foo => sub { OtherClass->new };
  
  # Create accessors at once
  has [qw/foo bar baz/];
  has [qw/foo bar baz/] => 0;
  
  # Create all accessors at once
  has [qw/foo bar baz/],
    some => 1,
    other => sub { 5 };

Use the class.

  # Create a new object
  my $obj = SomeClass->new;
  my $obj = SomeClass->new(foo => 1, bar => 2);
  my $obj = SomeClass->new({foo => 1, bar => 2});
  
  # Set and get value
  my $foo = $obj->foo;
  $obj->foo(1);

Inheritance

  package Foo;
  use Object::Simple -base;
  
  package Bar;
  use Foo -base;
  
  # Another way
  package Bar;
  use Object::Simple -base => 'Foo';

=head1 DESCRIPTION

L<Object::Simple> is L<Mojo::Base> porting.
you can use L<Mojo::Base> features.

L<Object::Simple> is a generator of accessor method,
such as L<Class::Accessor>, L<Mojo::Base>, or L<Moose>.

L<Class::Accessor> is simple, but lack offten used features.
C<new> method can't receive hash arguments.
Default value can't be specified.
If multipule values is set through the accessor,
its value is converted to array reference without warnings.

Some people find L<Moose> too complex, and dislike that 
it depends on outside modules. Some say that L<Moose> is 
almost like another language and does not fit the familiar 
perl syntax. In some cases, in particular smaller projects, 
some people feel that L<Moose> will increase complexity
and therefore decrease programmer efficiency.
In addition, L<Moose> can be slow at compile-time and 
its memory usage can get large.

L<Object::Simple> is the middle way between L<Class::Accessor>
and complex class builder. Only offten used features is
implemented has no dependency.
L<Object::Simple> is almost same as L<Mojo::Base>.

C<new> method can receive hash or hash reference.
You can specify default value.

If you like L<Mojo::Base>, L<Object::Simple> is good choice.

=head1 GUIDE

See L<Object::Simple::Guide> to know L<Object::Simple> details.

=head1 IMPORT OPTIONS

=head2 -base

you can inherit Object::Simple
and C<has> function is imported by C<-base> option.

  package Foo;
  use Object::Simple -base;
  
  has x => 1;
  has y => 2;

strict and warnings is automatically enabled and 
Perl 5.10 features(C<say>, C<state>, C<given> is imported.

You can also use C<-base> option in sub class
to inherit other class.
  
  # Bar inherit Foo
  package Bar;
  use Foo -base;

You can also use the following syntax.

  # Same as above
  package Bar;
  use Object::Simple -base => 'Foo';

=head1 FUNCTIONS

=head2 has

Create accessor.
  
  has 'foo';
  has [qw/foo bar baz/];
  has foo => 1;
  has foo => sub { {} };

Create accessor. C<has> receive
accessor name and default value.
Default value is optional.
If you want to create multipule accessors at once,
specify accessor names as array reference at first argument.

If you want to specify reference or object as default value,
it must be code reference
not to share the value with other objects.

Get and set a attribute value.

  my $foo = $obj->foo;
  $obj->foo(1);

If a default value is specified and the value is not exists,
you can get default value.

If a value is set, the accessor return self object.
So you can set a value repeatedly.

 $obj->foo(1)->bar(2);

You can create all accessors at once.

  has [qw/foo bar baz/],
    pot => 1,
    mer => sub { 5 };

=head1 METHODS

=head2 new

  my $obj = Object::Simple->new(foo => 1, bar => 2);
  my $obj = Object::Simple->new({foo => 1, bar => 2});

Create a new object. C<new> receive
hash or hash reference as arguments.

=head2 attr

  __PACKAGE__->attr('foo');
  __PACKAGE__->attr([qw/foo bar baz/]);
  __PACKAGE__->attr(foo => 1);
  __PACKAGE__->attr(foo => sub { {} });

  __PACKAGE__->attr(
    [qw/foo bar baz/],
    pot => 1,
    mer => sub { 5 }
  );

Create accessor.
C<attr> method usage is equal to C<has> method.

=head1 DEPRECATED FUNCTIONALITY

  class_attr method # will be removed 2017/1/1
  dual_attr method # will be removed 2017/1/1

=head1 BACKWARDS COMPATIBILITY POLICY

If a functionality is DEPRECATED, you can know it by DEPRECATED warnings.
You can check all DEPRECATED functionalities by document.
DEPRECATED functionality is removed after five years,
but if at least one person use the functionality and tell me that thing
I extend one year each time he tell me it.

EXPERIMENTAL functionality will be changed without warnings.

(This policy was changed at 2011/10/22)

=head1 BUGS

Tell me the bugs
by mail or github L<http://github.com/yuki-kimoto/Object-Simple>

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

