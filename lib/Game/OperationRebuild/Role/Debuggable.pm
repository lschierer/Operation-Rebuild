package Game::OperationRebuild::Role::Debuggable 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base -role;

# ABSTRACT: Shared --debug handling and random seed selection

use Game::OperationRebuild::Random;

use constant DEFAULT_DEBUG_SEED => 42;

has option debug_seed => (
  isa    => Int,
  writer => 1,
);

sub is_debug ($self) { $self->has_debug_seed }

# Turn the optional value of --debug into a seed: absent or empty means the
# default debug seed.
sub set_debug_from_option ($self, $value) {
  if (!length $value) {
    $self->set_debug_seed(DEFAULT_DEBUG_SEED);
  }
  elsif ($value =~ /\A\d+\z/) {
    $self->set_debug_seed($value + 0);
  }
  else {
    die "--debug takes an optional integer seed, not '$value'\n";
  }
  return $self;
}

sub make_rng ($self) {
  return Game::OperationRebuild::Random->new(
    $self->is_debug ? (seed => $self->debug_seed) : (),
  );
}

1;

__END__

=head1 DESCRIPTION

Normal play seeds its random source from the clock so every game differs.
With C<--debug> the seed is fixed, so developers can reproduce a game. The
option takes an optional integer (C<--debug=1234>); without one the seed is
C<DEFAULT_DEBUG_SEED> (42).

=attr debug_seed

Set only when debugging.

=method is_debug

True when a debug seed has been set.

=method set_debug_from_option

Interprets the value of a C<--debug[=N]> command line option.

=method make_rng

Returns a new L<Game::OperationRebuild::Random> using the debug seed when
debugging, or the current time otherwise.
