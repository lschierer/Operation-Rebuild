package Game::OperationRebuild::Rules 0.001;

use v5.42.0;
use utf8::all;

# ABSTRACT: Core rule tables and formulas derived from the SRD 5.2.1

use Carp qw(croak);
use Exporter 'import';
use POSIX qw(floor);

our @EXPORT_OK = qw(
  @ABILITIES %ABILITY_ABBREVIATION %SKILLS @SIZES %SPACE_FEET
  @DAMAGE_TYPES @SENSES @MOVEMENT_MODES
  ability_modifier proficiency_bonus skill_ability is_ability is_skill
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our @ABILITIES = qw(strength dexterity constitution intelligence wisdom charisma);

our %ABILITY_ABBREVIATION = (
  strength     => 'STR',
  dexterity    => 'DEX',
  constitution => 'CON',
  intelligence => 'INT',
  wisdom       => 'WIS',
  charisma     => 'CHA',
);

# Skill => governing ability.
our %SKILLS = (
  'acrobatics'      => 'dexterity',
  'animal handling' => 'wisdom',
  'arcana'          => 'intelligence',
  'athletics'       => 'strength',
  'deception'       => 'charisma',
  'history'         => 'intelligence',
  'insight'         => 'wisdom',
  'intimidation'    => 'charisma',
  'investigation'   => 'intelligence',
  'medicine'        => 'wisdom',
  'nature'          => 'intelligence',
  'perception'      => 'wisdom',
  'performance'     => 'charisma',
  'persuasion'      => 'charisma',
  'religion'        => 'intelligence',
  'sleight of hand' => 'dexterity',
  'stealth'         => 'dexterity',
  'survival'        => 'wisdom',
);

our @SIZES = qw(Tiny Small Medium Large Huge Gargantuan);

# Width of the square a creature of each size controls, in feet.
our %SPACE_FEET = (
  Tiny       => 2.5,
  Small      => 5,
  Medium     => 5,
  Large      => 10,
  Huge       => 15,
  Gargantuan => 20,
);

our @DAMAGE_TYPES = qw(
  acid bludgeoning cold fire force lightning necrotic
  piercing poison psychic radiant slashing thunder
);

our @SENSES = qw(blindsight darkvision tremorsense truesight);

our @MOVEMENT_MODES = qw(walk burrow climb fly swim);

sub ability_modifier ($score) {
  croak "ability score must be an integer, got '" . ($score // 'undef') . "'"
    unless defined $score && $score =~ /\A-?\d+\z/;
  return floor(($score - 10) / 2);
}

sub proficiency_bonus ($level) {
  croak "level must be an integer from 1 to 20, got '" . ($level // 'undef') . "'"
    unless defined $level && $level =~ /\A\d+\z/ && $level >= 1 && $level <= 20;
  return 2 + int(($level - 1) / 4);
}

sub is_ability ($name) { defined $name && exists $ABILITY_ABBREVIATION{$name} }
sub is_skill ($name)   { defined $name && exists $SKILLS{$name} }

sub skill_ability ($skill) {
  return $SKILLS{$skill} // croak "unknown skill '$skill'";
}

1;

__END__

=head1 SYNOPSIS

  use Game::OperationRebuild::Rules qw(ability_modifier proficiency_bonus);

  my $mod = ability_modifier(16);     # +3
  my $pb  = proficiency_bonus(5);     # +3

=head1 DESCRIPTION

Constants and formulas from the System Reference Document 5.2.1, kept apart
from any object so they are trivial to test. Ability, skill, damage type,
sense and size names are lower case (sizes are capitalized) and are the
vocabulary used by the data files.

The skill list still contains skills tied to magic, such as C<arcana>. They
are kept until the setting decides how to rename them.

=head1 EXPORTS

Nothing is exported by default. Use the C<:all> tag for everything.

=head2 Tables

C<@ABILITIES>, C<%ABILITY_ABBREVIATION>, C<%SKILLS>, C<@SIZES>,
C<%SPACE_FEET>, C<@DAMAGE_TYPES>, C<@SENSES>, C<@MOVEMENT_MODES>.

=head2 ability_modifier

C<ability_modifier($score)> returns C<floor(($score - 10) / 2)>.

=head2 proficiency_bonus

C<proficiency_bonus($level)> returns 2 at levels 1 to 4, 3 at 5 to 8, up to 6
at levels 17 to 20. Dies for levels outside 1 to 20.

=head2 skill_ability

C<skill_ability($skill)> returns the ability that governs the skill.

=head2 is_ability

=head2 is_skill

Boolean checks that a name is known.
