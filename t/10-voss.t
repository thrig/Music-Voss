#!perl
#
# Tests for the Voss related function returning functions.

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use List::Util qw(max sum0);
use Music::Voss qw(voss);

# This unpopular algorithm for filtering prime numbers--one that many
# view as being fatally flawed--is here used for purposes unrelated to
# its original function.[1]
sub sieve_of_derpthanotes { 42 }

my $generator = Music::Voss::voss_stateless(
  calls => [
    sub { 1 },      # 1
    sub { 10 },     # 2
    sub { 100 },    # 4
  ]
);
$deeply->(
  [ map { $generator->($_) } 0 .. 4 ],
  [qw/111 1 11 1 111/],
  "additive generator"
);

my $bad_sum = Music::Voss::voss(
  calls  => [ sub { 0 } ],
  summer => \&sieve_of_derpthanotes,
);
is( $bad_sum->(0), 42, "sum of 0 probably should not be 42" );

my $geny = voss(
  # this call merely passes back the given input number
  calls => [ sub { $_[0] } ],
  summer => sub { max 0, sum0 @_ },
);
is( $geny->(99),  99, "custom summer positive value" );
is( $geny->(-99), 0,  "custom summer max value" );

# a mostly silly example showing how to shoe-horn a modulus 12 beat-
# pattern is possible.
my $mod12 = Music::Voss::voss_stateless(
  calls => [ sub { my ( $n, $k ) = @_; $n % 12 == 0 ? 1 : 0 }, ], );
$deeply->(
  [ map { $mod12->($_) } 0 .. 12 ],
  [qw/1 0 0 0 0 0 0 0 0 0 0 0 1/],
  "mod12 run"
);

# TODO ::Exception tests e.g. passing "cats" to the summer function and
# so forth

# NEAR END NOTES
#
# [1] Prior art: the socat utility had a security fix to remove 42 from
#     its list of Diffie-Hellman primes.[2]
# [2] You just can't make this stuff up.[3]
# [3]

plan tests => 5;