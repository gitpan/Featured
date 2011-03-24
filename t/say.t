use strict;
use warnings;

use Test::More 0.98 tests => 3;

use Featured qw'say say_io';

sub just_skip{
  my($why,$how_many) = @_;
  $how_many ||= 1;

  SKIP: {
    skip $why, $how_many;
  }
  return 1;
}

sub test_stdout{
  my $output = '';
  open my $fh, '>', \$output;
  my $old_fh = select $fh;
  say @_;
  select $old_fh;
  return $output;
}

if( Featured::loaded_by('say','feature') ){
  just_skip( q['say' loaded by feature not Featured] );
}else{
  subtest q[Testing use Featured 'say'] =>  sub{
    print "\n";
    note q[Testing use Featured 'say'];
    plan tests => 1;

    my $output = test_stdout('Testing');
    is $output, "Testing\n", q[( say 'Testing' ) === ( print 'Testing', "\n" )];
  };
}
subtest q[Testing say_io with IO ref] => sub{
  print "\n";
  note q[Testing say_io with IO ref];
  plan tests => 2;
  {
    my $write = 'Testing';

    my $file;
    open my $fh, '>', \$file;
    say_io $fh, $write;
    close $fh;

    is $file, "$write\n", "say_io( \$fh, '$write' )";
  }
  {
    my @write = qw'Testing 1 2 3';

    my $file;
    open my $fh, '>', \$file;
    say_io $fh, @write;
    close $fh;

    my $expected = join('', @write)."\n";
    is $file, $expected, "say_io( \$fh, qw'@write' )";
  }
};

{
  package Fake;
  sub new{
    my($class,$str) = @_;
    bless \$str, $class;
  }
  package Fake::WithPrint;
  our @ISA = 'Fake';
  sub print{
    my $self = shift;
    local $" = '';
    $$self .= "@_";
    return 1;
  }
}

subtest q[say_io with object] => sub{
  print "\n";
  note q[say_io with object];
  plan tests => 5;
  {
    print "\n";
    note 'object without a print method';
    my $fake = Fake->new;
    ok !Featured::ref_is_object_with_print($fake), q[check that object doesn't have print method];

    my $write = 'Testing';
    local $@;
    ok !eval{
      say_io $fake, $write;
    }, q[object doesn't have print method];
  }
  {
    print "\n";
    note 'object with a print method';
    my $fake = Fake::WithPrint->new;
    ok Featured::ref_is_object_with_print($fake), q[check that object does have print method];

    my $write = 'Testing';
    ok say_io($fake, $write), q[say_io did write to object];
    is $$fake, "$write\n", q[object written to successfully];
  }
}

#diag explain \%Fake::;
