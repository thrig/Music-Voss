# -*- Perl -*-
#
# Functions for fractal noise generation functions, mostly adapted from
# "Musimathics, Vol 1" p.354-358.
#
# Run perldoc(1) on this file for additional documentation.

package Music::Voss;

use 5.010000;
use strict;
use warnings;
use Carp qw(croak);
use Exporter 'import';
use List::Util ();
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

our @EXPORT_OK = qw(voss voss_stateless);

# Voss's Method Generator (actually by way of Martin Gardner)
sub voss {
  my (%params) = @_;
  croak "must be given list of calls"
    if !$params{calls}
    or ref $params{calls} ne 'ARRAY';
  if ( !exists $params{summer} ) {
    $params{summer} = \&List::Util::sum0;
  } elsif ( ref $params{summer} ne 'CODE' ) {
    croak "summer must be code reference";
  }
  my @nums = (0) x @{ $params{calls} };
  return sub {
    my ($n) = @_;
    croak "input must be number" if !defined $n or !looks_like_number $n;
    for my $k ( 0 .. $#{ $params{calls} } ) {
      if ( $n % 2**$k == 0 ) {
        $nums[$k] = $params{calls}->[$k]->( $n, $k );
      }
    }
    return $params{summer}->(@nums);
  }
}

sub voss_stateless {
  my (%params) = @_;
  croak "must be given list of calls"
    if !$params{calls}
    or ref $params{calls} ne 'ARRAY';
  if ( !exists $params{summer} ) {
    $params{summer} = \&List::Util::sum0;
  } elsif ( ref $params{summer} ne 'CODE' ) {
    croak "summer must be code reference";
  }
  return sub {
    my ($n) = @_;
    croak "input must be number" if !defined $n or !looks_like_number $n;
    my @nums;
    for my $k ( 0 .. $#{ $params{calls} } ) {
      push @nums, $params{calls}->[$k]->( $n, $k ) if $n % 2**$k == 0;
    }
    return $params{summer}->(@nums);
  }
}

1;
__END__

=head1 NAME

Music::Voss - functions for fractal noise generation functions

=head1 SYNOPSIS

  use List::Util qw(max sum0);
  use Music::Voss qw(voss);

  # generate a generator function
  my $genf = voss( calls => [
    sub { int rand 2 },  # k=0, 2**k == 1 (every value)
    sub { int rand 2 },  # k=1, 2**k == 2 (every other value)
    sub { int rand 2 },  # k=2, 2**k == 4 ...
    sub { int rand 2 },  # k=3, ...
    ...
  ]);

  # or with a custom summation function (default: sum0)
  # that limits results to not-negative values
  my $geny = voss(
    calls  => [ sub { 5 - int rand 10 } ], 
    summer => sub { max 0, sum0 @_ },
  );

  # generate numbers for some input values
  for my $x (0..21) {
    printf "%d %d %d\n", $x, $genf->($x), $geny->($x);
  }

  # or to obtain a list of values (NOTE TODO FIXME the voss() generated
  # functions maintain state and there is (as yet) no way to inspect or
  # reset that state)
  my @values = map { $genf->($_) } 0..21;

=head1 DESCRIPTION

This module contains functions that generate functions that may then be
called in turn with a sequence of numbers to generate numbers. Given how
hopelessly vague this may sound, let us move on to the

=head1 FUNCTIONS

These are not exported, and must be manually imported or called with the
full module path.

=over 4

=item B<voss>

This function returns a function that in turn should be called with
(ideally successive) integers. The generated function uses powers-of-two
modulus math on the array index of the list of given C<calls> to
determine when the result from a particular call should be saved to an
array internal to the generated function. A custom C<summer> function
may be supplied to B<voss> that will sum the resulting list of numbers;
the default is to call C<sum0> of L<List::Util> and return that sum.

The C<calls> functions are passed two arguments, the given number, and
the array index that triggered the call. C<calls> functions probably
should return a number. Typically, the C<calls> return random values,
though other patterns are certainly worth experimenting with, such as a
mix of random values and other values that are iterated through:

  use Music::AtonalUtil;
  use Music::Voss qw(voss);
  my $atu = Music::AtonalUtil->new;

  my @values = qw/0 0 2 1 1 2 0/;
  my $genf = voss(
    calls => [
      sub { 1 - int rand 2 },   # 1
      sub { 0 },                # 2
      sub { 1 - int rand 2 },   # 4
      sub { 1 - int rand 2 },   # 8
      $atu->nexti( \@values )   # 16
    ]);

The generated function ideally should be fed sequences of integers that
increment by one. This means that the slower-changing values from higher
array indexed C<calls> will persist through subsequent calls. If this is
a problem, consider instead the

=item B<voss_stateless>

function, which is exactly like B<voss>, only it does not keep state
through repeated calls the the returned function. Likely useful for
rhythmic (or MIDI velocity) related purposes, assuming those purposes
can be shoehorned into the powers-of-two modulus model of the B<voss>
function. And they can be! A mod 12 rhythm would be possible via
something like:

  my $mod12 = Music::Voss::voss_stateless( calls => [ sub {
    my ( $n, $k ) = @_;
    $n % 12 == 0 ? 1 : 0
  }, ]);
  for my $x (0..$whatevs) {
    my $y = $mod12->($x);
    ...

Though, any such math must bear in mind that C<calls> beyond the first
are only called on every 2nd, 4th, etc. input value (assuming as ever
that the input values are a list of integers that being on an even value
and increment by one for each successive call).

=back

TODO Weierstrass functions, Brownian motion, etc.

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-pitchnum at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Voss>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-Voss>

=head2 Known Issues

The functions returned by some functions of this module probably should
not be used in a threaded environment, on account of unknown results
should multiple threads call the same function around the same time.
This may actually be a feature for experimental musical composition.

The not nearly enough functions written problem. Also, need multiple
return values from the function returning functions, with the remaining
functions being means to reset or otherwise interact with any state
maintained by the function.

The lack of testing. (Bad input values, whether anything sketchy is
going on with the closures, etc.)

=head1 SEE ALSO

L<MIDI::Simple> or L<Music::Scala> or L<Music::LilyPondUtil> have means
to convert numbers (such as produced by the functions returned by the
functions of this module) into MIDI events, frequencies, or a form
suitable to pass to lilypond. L<Music::Canon> (or the C<canonical>
program by way of L<App::MusicTools>) may also be of interest.

=head2 REFERENCES

=over 4

=item *

Musimathics, Vol. 1, p.354-358 by Gareth Loy.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
