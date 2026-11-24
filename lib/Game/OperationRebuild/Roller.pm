package Game::OperationRebuild::Roller 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Dice expressions rolled from a seedable random source

use Carp qw(croak);
use Games::Dice::Advanced;
use Game::OperationRebuild::Random;

# The notation the rules need: NdS, optionally keeping or dropping the highest
# or lowest dice, optionally a fixed modifier.
my $EXPRESSION = qr/\A\s*(\d*)d(\d+)(?:(kh|kl|dh|dl)(\d+))?\s*(?:([+-])\s*(\d+))?\s*\z/i;

has param rng => (
  isa     => InstanceOf ['Game::OperationRebuild::Random'],
  default => sub { Game::OperationRebuild::Random->new },
);

# Games::Dice::Advanced 1.2 as released has neither the "rand" option nor the
# keep/drop notation. Both are in the branches the author has submitted
# upstream; until a release contains them, the fork must be installed. See
# the INSTALL file. Checked once, when the first Roller is built.
my $ENGINE_CHECKED;

sub _check_engine () {
  return if $ENGINE_CHECKED;
  my $calls = 0;
  my $total = eval {
    Games::Dice::Advanced->new('2d6kh1', { rand => sub { $calls++; $_[0] - 0.5 } })->roll;
  };
  croak "The installed Games::Dice::Advanced does not support the 'rand' option and "
    . "keep/drop notation. Install the version from "
    . "https://github.com/lschierer/perl-modules-Games-Dice-Advanced (see INSTALL)."
    unless defined $total && $calls == 2 && $total == 6;
  return $ENGINE_CHECKED = 1;
}

sub BUILD ($self, $args) {
  _check_engine();
  return;
}

# Returns the validated expression in canonical form (an omitted dice count
# means one die), or dies. Returns the dice part and the modifier separately.
sub _parse ($self, $expression) {
  croak "dice expression is required" unless defined $expression && length $expression;
  my ($count, $sides, $keep, $keep_n, $sign, $modifier) = $expression =~ $EXPRESSION
    or croak "unsupported dice expression '$expression'";
  $count = 1 if $count eq '';
  croak "dice expression '$expression' needs 1 to 100 dice and 2 to 1000 sides"
    unless $count >= 1 && $count <= 100 && $sides >= 2 && $sides <= 1000;
  croak "dice expression '$expression' keeps or drops more dice than it rolls"
    if defined $keep && ($keep_n < 1 || $keep_n >= $count + (lc($keep) =~ /^k/ ? 1 : 0));

  my $dice = "${count}d${sides}" . (defined $keep ? lc($keep) . $keep_n : '');
  my $signed = defined $sign ? ($sign eq '-' ? -$modifier : $modifier + 0) : 0;
  return ($dice, $signed);
}

sub roll_detail ($self, $expression) {
  my ($dice, $modifier) = $self->_parse($expression);
  my $rng = $self->rng;
  # The engine calls this wherever it would call rand($faces).
  my $total = Games::Dice::Advanced->new($dice, { rand => sub ($faces) { $rng->next_float * $faces } })->roll;
  $total += $modifier;
  return {
    expression => $dice . ($modifier ? sprintf('%+d', $modifier) : ''),
    total      => $total,
  };
}

sub roll ($self, $expression) {
  return $self->roll_detail($expression)->{total};
}

# A d20 test with advantage (roll two, keep the higher) or disadvantage (keep
# the lower); anything else rolls one die. Advantage and disadvantage together
# cancel out, so callers pass at most one of them.
sub d20 ($self, $mode = 'normal', $modifier = 0) {
  my %base = (normal => '1d20', advantage => '2d20kh1', disadvantage => '2d20kl1');
  my $expression = $base{$mode} // croak "unknown roll mode '$mode'";
  $expression .= sprintf('%+d', $modifier) if $modifier;
  return $self->roll_detail($expression)->{total};
}

1;

__END__

=head1 SYNOPSIS

  my $rng    = Game::OperationRebuild::Random->new(seed => 42);
  my $roller = Game::OperationRebuild::Roller->new(rng => $rng);

  my $strength = $roller->roll('4d6kh3');          # roll four, keep the best three
  my $attack   = $roller->d20('advantage', 5);     # 2d20, keep highest, +5
  my $info     = $roller->roll_detail('2d6+3');    # { total => ..., detail => ... }

=head1 DESCRIPTION

Rolls dice expressions with L<Games::Dice::Advanced>, but takes every random
number from a L<Game::OperationRebuild::Random> object instead of Perl's
global C<rand>. A given seed therefore always produces the same rolls, which
is what the C<--debug> option and the tests rely on.

Accepted notation: C<NdS>, with C<N> optional (C<d20> is C<1d20>), optionally
C<khN>, C<klN>, C<dhN> or C<dlN> to keep or drop the highest or lowest N dice,
and an optional C<+M> or C<-M>. Anything else dies.

=head2 Requirement

This needs a L<Games::Dice::Advanced> that has the C<rand> option and the
keep/drop notation. Those changes were submitted upstream. Until a release
contains them, install the fork described in F<INSTALL>. Building a Roller
checks for them and dies with that instruction if they are missing.

=attr rng

The L<Game::OperationRebuild::Random> source. A new, clock-seeded one is used
if none is given.

=method roll

Returns the total of an expression.

=method roll_detail

Returns a hash with C<expression> (normalised) and C<total>. The individual
dice are not reported.

=method d20

C<< $roller->d20($mode, $modifier) >> rolls a d20 test. C<$mode> is
C<normal> (default), C<advantage> or C<disadvantage>.
