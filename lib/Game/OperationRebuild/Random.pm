package Game::OperationRebuild::Random 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Seedable, platform-independent random number source

# The 48-bit arithmetic below needs 64-bit integers.
use Config;
BEGIN { die "64-bit integers are required\n" if $Config{ivsize} < 8 }
no warnings 'portable';

use constant MASK48 => 0xFFFF_FFFF_FFFF;

has param seed => (
  isa     => Int,
  default => sub { time },
);

has field _state => (
  writer  => 1,
  lazy    => 1,
  default => sub ($self) {
    # Same initialisation as srand48(): seed in the high 32 bits.
    ((($self->seed & 0xFFFF_FFFF) << 16) | 0x330E);
  },
);

sub next_float ($self) {
  # 48-bit linear congruential generator (the drand48 recurrence). The
  # product wraps modulo 2**64, which is harmless because we keep 48 bits.
  my $x;
  {
    use integer;
    $x = ($self->_state * 0x5DEECE66D + 0xB) & MASK48;
  }
  $self->_set_state($x);
  return $x / 281_474_976_710_656;    # 2**48
}

sub int_between ($self, $low, $high) {
  die "int_between: low ($low) is greater than high ($high)\n" if $low > $high;
  return $low + int($self->next_float * ($high - $low + 1));
}

1;

__END__

=head1 SYNOPSIS

  my $rng = Game::OperationRebuild::Random->new(seed => 42);
  my $roll = $rng->int_between(1, 20);

=head1 DESCRIPTION

All game randomness goes through an instance of this class instead of
Perl's global C<rand>, so that a game, a map, or a test can be reproduced
from a seed. Two instances with the same seed produce the same sequence on
every platform. Without a C<seed> the current time is used.

This generator is not suitable for cryptography.

=attr seed

Integer seed, defaulting to C<time>.

=method next_float

Returns the next number in the range C<[0, 1)>.

=method int_between

C<< $rng->int_between($low, $high) >> returns an integer from C<$low> to
C<$high>, inclusive.
