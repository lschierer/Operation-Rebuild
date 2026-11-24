package Game::OperationRebuild::Creature 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: A character or monster whose statistics come from a base plus effects

use Carp qw(croak);
use List::Util qw(max sum0 uniq);
use Game::OperationRebuild::Rules qw(
  @ABILITIES @SENSES @MOVEMENT_MODES
  ability_modifier skill_ability is_ability is_skill
);

use constant ABILITY_SCORE_CAP => 20;

has param name  => (isa => Str, default => '');
has param level => (isa => IntRange [ 1, 20 ], default => 1);

# Base ability scores before any effect, keyed by full ability name.
has param abilities => (isa => HashRef [Int]);

has option species => (isa => InstanceOf ['Game::OperationRebuild::Species']);

# Traits that do not come from the species (class, background, technology).
has param traits => (
  isa     => ArrayRef [ InstanceOf ['Game::OperationRebuild::Trait'] ],
  default => sub { [] },
);

# Proficiencies chosen at creation, in addition to those effects grant.
has param skill_proficiencies => (isa => ArrayRef [Str], default => sub { [] });
has param save_proficiencies  => (isa => ArrayRef [Str], default => sub { [] });

# Sides of the class Hit Die (for example 12 for a barbarian).
has option hit_die => (isa => PositiveInt);

sub BUILD ($self, $args) {
  my $abilities = $self->abilities;
  for my $ability (@ABILITIES) {
    croak "missing ability score '$ability'" unless defined $abilities->{$ability};
    croak "ability score '$ability' must be 1 to 30"
      unless $abilities->{$ability} >= 1 && $abilities->{$ability} <= 30;
  }
  my @unknown = grep { !is_ability($_) } keys %$abilities;
  croak "unknown abilities: @unknown" if @unknown;
  croak "unknown skill '$_'" for grep { !is_skill($_) } $self->skill_proficiencies->@*;
  croak "unknown ability '$_'" for grep { !is_ability($_) } $self->save_proficiencies->@*;
  return;
}

sub all_traits ($self) {
  return (
    ($self->has_species ? $self->species->traits->@* : ()),
    $self->traits->@*,
  );
}

sub effects ($self, $kind = undef) {
  my @effects = map { $_->active_effects } $self->all_traits;
  return $kind ? grep { $_->kind eq $kind } @effects : @effects;
}

sub _targeted ($self, $kind, $target) {
  return grep { $_->target eq $target } $self->effects($kind);
}

sub size ($self) { $self->has_species ? $self->species->size : 'Medium' }

sub ability_score ($self, $ability) {
  croak "unknown ability '$ability'" unless is_ability($ability);
  my @effects = $self->_targeted(ability_score => $ability);

  my $score = $self->abilities->{$ability};
  $score += sum0 map { $_->value } grep { $_->mode eq 'add' } @effects;
  $score = ABILITY_SCORE_CAP if $score > ABILITY_SCORE_CAP;
  # "set" effects raise a score to a value but never lower it, and are
  # allowed to exceed the normal cap.
  $score = max($score, map { $_->value } grep { $_->mode eq 'set' } @effects);
  return $score;
}

sub ability_modifier_for ($self, $ability) {
  return ability_modifier($self->ability_score($ability));
}

sub proficiency_bonus ($self) {
  return Game::OperationRebuild::Rules::proficiency_bonus($self->level);
}

sub skill_proficient ($self, $skill) {
  croak "unknown skill '$skill'" unless is_skill($skill);
  return 1 if grep { $_ eq $skill } $self->skill_proficiencies->@*;
  return 1 if $self->_targeted(skill_proficiency => $skill);
  return 0;
}

sub save_proficient ($self, $ability) {
  croak "unknown ability '$ability'" unless is_ability($ability);
  return 1 if grep { $_ eq $ability } $self->save_proficiencies->@*;
  return 1 if $self->_targeted(save_proficiency => $ability);
  return 0;
}

sub skill_bonus ($self, $skill) {
  my $bonus = $self->ability_modifier_for(skill_ability($skill));
  $bonus += $self->proficiency_bonus if $self->skill_proficient($skill);
  return $bonus;
}

sub save_bonus ($self, $ability) {
  my $bonus = $self->ability_modifier_for($ability);
  $bonus += $self->proficiency_bonus if $self->save_proficient($ability);
  return $bonus;
}

sub speed ($self, $mode = 'walk') {
  croak "unknown movement mode '$mode'" unless grep { $_ eq $mode } @MOVEMENT_MODES;
  my @effects = $self->_targeted(speed => $mode);
  my $speed   = ($mode eq 'walk' && $self->has_species) ? $self->species->speed : 0;
  $speed += sum0 map { $_->value } grep { $_->mode eq 'add' } @effects;
  return max($speed, map { $_->value } grep { $_->mode eq 'set' } @effects);
}

sub sense_range ($self, $sense) {
  croak "unknown sense '$sense'" unless grep { $_ eq $sense } @SENSES;
  return max(0, map { $_->value } $self->_targeted(sense => $sense));
}

sub resistances ($self) {
  return sort(uniq(map { $_->target } $self->effects('resistance')));
}

sub has_advantage ($self, $tag) {
  return scalar($self->_targeted(advantage => $tag)) ? 1 : 0;
}

sub has_disadvantage ($self, $tag) {
  return scalar($self->_targeted(disadvantage => $tag)) ? 1 : 0;
}

# Hit points: maximum die at level 1, the fixed average (rounded up) for each
# later level, plus the Constitution modifier each level, plus effects such as
# Dwarven Toughness. Each level gives at least 1 hit point.
sub max_hit_points ($self) {
  my $die = $self->hit_die // croak "max_hit_points needs a hit_die";
  my $con = $self->ability_modifier_for('constitution');
  my $per_level = sum0 map { $_->value } $self->effects('hit_points_per_level');

  my $hp = max(1, $die + $con);
  $hp += max(1, int($die / 2) + 1 + $con) * ($self->level - 1);
  $hp += $per_level * $self->level;
  return $hp;
}

1;

__END__

=head1 SYNOPSIS

  my $creature = Game::OperationRebuild::Creature->new(
    level     => 3,
    abilities => { strength => 15, dexterity => 12, constitution => 14,
                   intelligence => 8, wisdom => 10, charisma => 9 },
    species   => $dwarf,
    hit_die   => 12,
  );
  say $creature->ability_modifier_for('constitution');
  say $creature->max_hit_points;

=head1 DESCRIPTION

A creature stores only its base values. Everything else (final ability
scores, skill bonuses, speed, senses, resistances, hit points) is computed
on request by applying the effects of its species and traits. That keeps the
tech tree, equipment and age stages able to add effects without special
cases. Monsters and player characters will share this model.

Ability scores are capped at 20 after additive effects. A C<set> effect
raises a score to at least a given value and may exceed the cap.

=attr name

Display name.

=attr level

Character level, 1 to 20.

=attr abilities

Base ability scores, keyed by full ability name.

=attr species

Optional L<Game::OperationRebuild::Species>.

=attr traits

Traits not supplied by the species.

=attr skill_proficiencies

Skills chosen at creation, in addition to those effects grant.

=attr save_proficiencies

Saving throw proficiencies, in addition to those effects grant.

=attr hit_die

Sides of the class Hit Die. Needed only by C<max_hit_points>.

=method all_traits

Species traits followed by the creature's own.

=method effects

All active effects, optionally limited to one kind.

=method size

The species size, or C<Medium> without a species.

=method ability_score

Final score for an ability.

=method ability_modifier_for

Modifier for the final score of an ability.

=method proficiency_bonus

Bonus for the creature's level.

=method skill_proficient

=method save_proficient

Whether the creature is proficient.

=method skill_bonus

=method save_bonus

Modifier plus proficiency bonus when proficient.

=method speed

Speed in feet for a movement mode (default C<walk>).

=method sense_range

Range in feet of a sense, or 0.

=method resistances

Sorted list of damage types resisted.

=method has_advantage

=method has_disadvantage

Whether an effect grants (dis)advantage on a tag.

=method max_hit_points

Maximum hit points. Dies unless C<hit_die> is set.
