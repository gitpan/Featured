package Featured;
BEGIN {
  $Featured::VERSION = '0.000002'; # TRIAL
}
use strict;
use warnings;
require 5.006;

use Package::Stash;

our %feature;
our %own;
our $has_feature_module;

BEGIN{
  my @own = qw{
    say_io
  };
  my @both = qw{
    say
  };
  %own = map{
    $_, 1
  } @own;
  %feature = map{
    $_, undef
  } @own, @both;

  # load feature if it can be found
  # and set $has_feature_module
  $has_feature_module = !! eval{ require feature };

  if($has_feature_module){
    feature->import('say');
  }

  # Monkey patch older versions ( before 0.14 ) of Package::Stash
  if( $Package::Stash::VERSION < 0.14 ){
    my $stash = Package::Stash->new('Package::Stash');

    my %package_methods = qw{
      add_symbol    add_package_symbol
      remove_symbol remove_package_symbol
    };
    while( my($new,$old) = each %package_methods ){
      no strict 'refs';
      $new = '&'.$new;
      $old = 'Package::Stash::'.$old;
      # make sure that nobody else has already done this
      unless( $stash->has_package_symbol($new) ){
        $stash->add_package_symbol($new,\&$old);
      }
    }
  }
}

sub loaded_by{
  my($name,$package) = @_;

  # not loaded
  return unless $feature{$name};

  if( $package ){
    return $feature{$name} eq $package ? $package : ();
  }else{
    return $feature{$name};
  }
}

sub import {
  my $class = shift;
  if (@_ == 0) {
    croak("No features specified");
  }
  my $callpkg = caller;
  my $stash = Package::Stash->new($callpkg);

  while (@_) {
    my $name = shift(@_);
    if (substr($name, 0, 1) eq ":") {
      next;
    }

    next if try_feature($name);

    if (!exists $feature{$name}) {
      unknown_feature($name);
    }else{
      $feature{$name} = __PACKAGE__;

      my $internal = '_'.$name;
      $stash->add_symbol( '&'.$name, \&$internal );
    }
  }

  return 1;
}

sub unimport{
  my $class = shift;
  my $callpkg = caller;
  my $stash = Package::Stash->new($callpkg);;

  unless( @_ ){
    @_ = grep{
      $feature{$_}
    } keys %feature;
  }

  for my $name( @_ ){
    my $loaded_by = loaded_by($name);

    if( $loaded_by eq __PACKAGE__ ){
      $stash->remove_symbol( '&'.$name );
    }elsif( $loaded_by eq 'feature' ){
      feature->unimport($name);
    }elsif( exists $feature{$name} ){
      # not loaded
    }else{
      unknown_feature($name);
    }
  }

  return 1;
}

# try to load with L<feature>
sub try_feature{
  return unless $has_feature_module;

  my($name) = @_;

  return if exists $own{$name};

  my $result = eval { feature->import($name); 1 };

  if( $result ){
    $feature{$name} = 'feature';
    return 1;
  }
  return;
}

sub unknown_feature {
  my($feature) = @_;
  no strict 'vars';
  croak(sprintf('Feature "%s" is not supported by Featured %d', $feature, $VERSION));
}

sub croak {
  require Carp;
  Carp::croak(@_);
}

sub ref_is_IO{
  my($ref) = @_;
  my $reftype = ref $ref;
  return unless $reftype;

  return $ref if $reftype eq 'IO';

  if( $reftype eq 'GLOB' ){
    my $has_io = *{$ref}{IO};
    return $has_io if $has_io;
  }

  return;
}

sub ref_is_object_with_print{
  my($ref) = @_;
  require Scalar::Util;
  return unless Scalar::Util::blessed $ref;

  return $ref if $ref->can('print');
  return;
}

# our implementation of C<say>
sub _say{
  print @_, "\n";
}

sub _say_io{
  my $handle = shift;

  if( ref_is_IO($handle) ){
    if( loaded_by( 'say', 'feature' ) ){
      # use the native say, if it's available
      return say {$handle} @_;
    }else{
      # fall-back to using print
      return print {$handle} @_, "\n";
    }

  }elsif( ref_is_object_with_print($handle) ){
    return $handle->print( @_, "\n" );

  }else{
    # since C<say> doesn't die, neither do we
    return;
  }
}
1;
# ABSTRACT: Use featured keywords on older Perls


__END__
=pod

=head1 NAME

Featured - Use featured keywords on older Perls

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

    require 5.006;

    use Featured 'say';
    say 'hi';

=head1 DESCRIPTION

Enables the use of features from newer Perl's,
without actually needing that version of Perl.

Tries to enable the features through L<feature> first, if it's available.

=head1 FEATURES

=over 4

=item C<say>

A minimal re-implementation of say from Perl v5.10
for older versions of Perl.

On Perl versions that natively support C<say>,
it enables the native version instead.

=item C<say_io> I<expiremental>

This exists since this implementation of C<say> doesn't
support writing to handles other than the currently selected one.

    use Featured 'say_io';
    open my $fh, '>', 'example.txt';
    say_io $fh, 'hello';

=back

=for Pod::Coverage croak unknown_feature try_feature loaded_by ref_is_IO ref_is_object_with_print import unimport

=head1 AUTHOR

Brad Gilbert <b2gills@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Brad Gilbert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

