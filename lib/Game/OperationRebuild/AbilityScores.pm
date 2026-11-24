package Game::OperationRebuild::AbilityScores 0.001;

use v5.42.0;
use utf8::all;

# ABSTRACT: The SRD's three ways to generate a set of ability scores

use Carp qw(croak);
use List::Util qw(sum0);
use Game::OperationRebuild::Rules qw(@ABILITIES is_ability);

use constant POINT_BUY_BUDGET => 27;
use constant STANDARD_ARRAY   => (15, 14, 13, 12, 10, 8);

our %POINT_COST = (8 => 0, 9 => 1, 10 => 2, 11 => 3, 12 => 4, 13 => 5, 14 => 7, 15 => 9);

# Returns six scores, highest first, from the SRD's random method: roll four
# d6 and keep the highest three, six times.
sub roll_set ($class, $roller) {
  return sort { $b <=> $a } map { $roller->roll('4d6kh3') } 1 .. 6;
}

sub standard_array ($class) { return (STANDARD_ARRAY) }

sub point_cost ($class, $score) {
  return $POINT_COST{$score} // croak "no point cost for a score of $score (allowed: 8 to 15)";
}

# Points spent by a hash of ability => score.
sub points_spent ($class, $scores) {
  return sum0 map { $class->point_cost($_) } values %$scores;
}

# Checks a point-buy hash: every ability present, each score 8 to 15, no more
# than 27 points spent. Returns the scores, or dies.
sub validate_point_buy ($class, $scores) {
  $class->_check_abilities($scores);
  my $spent = $class->points_spent($scores);
  croak "point buy spends $spent points, more than " . POINT_BUY_BUDGET if $spent > POINT_BUY_BUDGET;
  return $scores;
}

# Assigns a list of six scores to the abilities, in the order given
# (the six full ability names, in any order, each once).
sub assign ($class, $values, $order) {
  croak "need six scores" unless @$values == 6;
  croak "need six abilities" unless @$order == 6;
  my %seen;
  for my $ability (@$order) {
    croak "unknown ability '$ability'" unless is_ability($ability);
    croak "ability '$ability' assigned twice" if $seen{$ability}++;
  }
  my %scores;
  @scores{@$order} = @$values;
  return \%scores;
}

# Assigns the standard array. The values must be exactly the standard array.
sub assign_standard_array ($class, $values, $order) {
  my @given    = sort { $b <=> $a } @$values;
  my @expected = (STANDARD_ARRAY);
  croak "scores are not the standard array" unless "@given" eq "@expected";
  return $class->assign($values, $order);
}

sub _check_abilities ($class, $scores) {
  for my $ability (@ABILITIES) {
    croak "missing ability score '$ability'" unless defined $scores->{$ability};
  }
  my @extra = grep { !is_ability($_) } keys %$scores;
  croak "unknown abilities: @extra" if @extra;
  return;
}

1;

__END__

=head1 SYNOPSIS

  my $roller = Game::OperationRebuild::Roller->new(
    rng => Game::OperationRebuild::Random->new(seed => 42));

  my @rolled = Game::OperationRebuild::AbilityScores->roll_set($roller);
  my $scores = Game::OperationRebuild::AbilityScores->assign(
    \@rolled, [qw(strength constitution dexterity wisdom intelligence charisma)]);

=head1 DESCRIPTION

Implements step 3 of SRD character creation. A character's six scores come
from one of three methods: the standard array (15, 14, 13, 12, 10, 8), random
generation (four d6, keep the three highest, six times), or point buy (27
points; costs from 0 for a score of 8 to 9 for a score of 15). The player
then assigns the numbers to abilities. Background bonuses are applied
afterwards, as effects.

All methods are class methods.

=method roll_set

C<< ->roll_set($roller) >> returns six scores, highest first.

=method standard_array

The six standard array scores.

=method point_cost

Cost of one score in point buy. Dies outside 8 to 15.

=method points_spent

Total cost of a hash of ability to score.

=method validate_point_buy

Checks a point-buy hash and returns it. Dies if an ability is missing, a score
is outside 8 to 15, or more than 27 points are spent.

=method assign

C<< ->assign(\@values, \@abilities) >> pairs the values with the abilities and
returns a hash of ability to score.

=method assign_standard_array

Like C<assign>, but dies unless the values are exactly the standard array.
