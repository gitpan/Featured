use strict;
use warnings;

use Test::More 0.98 tests => 2;

require Featured;

ok(
  ! eval{ Featured->import('non_existent'); 1 },
  'Die when trying to use non-existent features'
);
like(
  $@,
  qr{^Feature "non_existent"},
  'Check error message for non-existent features'
);
