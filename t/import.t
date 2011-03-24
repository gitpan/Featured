use strict;
use warnings;

no warnings qw'once uninitialized';

use Test::More 0.98 tests => 6;
use Package::Stash;

require Featured;

{
  package Fake;
  sub add{
    my($class) = @_;
    shift if $class eq __PACKAGE__;

    Featured->import(@_);
  }
  sub remove{
    my($class) = @_;
    shift if $class eq __PACKAGE__;

    Featured->unimport(@_);
  }
}

my $stash = Package::Stash->new('Fake');

# add say
Fake->add('say');
note 'say was loaded by ', Featured::loaded_by('say');
ok( Featured::loaded_by('say'), 'say had to be loaded by someone' );

# this should only fail if someone has copied feature.pm
ok(
  (!!Featured::loaded_by('say','feature')) == $Featured::has_feature_module,
  'say should be loaded by feature if it can be found'
);

# remove say
Fake->remove('say');
ok( ! $stash->has_symbol('&say'), 'say should be gone now' );

# add say_io
Fake->add('say_io');
ok(
  Featured::loaded_by('say_io','Featured'),
  'say_io had to be loaded by Featured'
);
ok( $stash->has_symbol('&say_io'), 'say_io should be there' );

# remove say_io
Fake->remove('say_io');
ok( ! $stash->has_symbol('&say_io'), 'say_io should be gone now' );
