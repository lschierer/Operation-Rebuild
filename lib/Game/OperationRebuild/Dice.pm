package Game::OperationRebuild::Dice 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Dice expressions such as 2d6+3

has param count    => (isa => PositiveInt, default => 1);
has param sides    => (isa => PositiveInt);
has param modifier => (isa => Int, default => 0);

sub parse ($class, $text) {
  $text =~ m{\A \s* (\d*) \s* [dD] \s* (\d+) \s* (?: ([+-]) \s* (\d+) )? \s* \z}x
    or die "Cannot parse dice expression '$text'\n";
  my ($count, $sides, $sign, $mod) = ($1, $2, $3, $4);
  return $class->new(
    count    => length $count ? $count + 0 : 1,
    sides    => $sides + 0,
    modifier => defined $mod ? ($sign eq '-' ? -$mod : $mod) : 0,
  );
}

sub roll_dice ($self, $rng) {
  return map { $rng->int_between(1, $self->sides) } 1 .. $self->count;
}

sub roll ($self, $rng) {
  my $total = $self->modifier;
  $total += $_ for $self->roll_dice($rng);
  return $total;
}

sub minimum ($self) { $self->count + $self->modifier }
sub maximum ($self) { $self->count * $self->sides + $self->modifier }

sub to_string ($self) {
  my $m = $self->modifier;
  return $self->count . 'd' . $self->sides . ($m ? sprintf('%+d', $m) : '');
}

1;

__END__

=head1 SYNOPSIS

  my $dice = Game::OperationRebuild::Dice->parse('2d6+3');
  my $rng  = Game::OperationRebuild::Random->new(seed => 7);
  say $dice->roll($rng);

=head1 DESCRIPTION

A count of identical dice plus a fixed modifier, as used throughout the
SRD-derived rules. Rolling requires a L<Game::OperationRebuild::Random>
object so results are reproducible.

=attr count

Number of dice, default 1.

=attr sides

Number of sides on each die.

=attr modifier

Integer added to the sum, default 0.

=method parse

C<< Game::OperationRebuild::Dice->parse('1d20-1') >> builds an object from
text. It dies if the text is not a dice expression.

=method roll

Rolls all dice with the given random source and returns the total.

=method roll_dice

Returns the list of individual die results.

=method minimum

=method maximum

Lowest and highest possible totals.

=method to_string

Canonical text form, such as C<2d6+3>.
