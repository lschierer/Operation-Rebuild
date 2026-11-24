use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Rules qw(:all);

subtest 'ability modifiers follow the SRD table' => sub {
  my %expected = (
    1 => -5, 3 => -4, 4 => -3, 5 => -3, 6 => -2, 7 => -2, 8 => -1, 9 => -1,
    10 => 0, 11 => 0, 12 => 1, 13 => 1, 14 => 2, 15 => 2, 16 => 3, 17 => 3,
    18 => 4, 19 => 4, 20 => 5, 30 => 10,
  );
  for my $score (sort { $a <=> $b } keys %expected) {
    is(ability_modifier($score), $expected{$score}, "score $score");
  }
  like(dies { ability_modifier('x') }, qr/integer/, 'rejects junk');
  like(dies { ability_modifier(undef) }, qr/integer/, 'rejects undef');
};

subtest 'proficiency bonus by level' => sub {
  my %expected = (1 => 2, 4 => 2, 5 => 3, 8 => 3, 9 => 4, 12 => 4, 13 => 5, 16 => 5, 17 => 6, 20 => 6);
  is(proficiency_bonus($_), $expected{$_}, "level $_") for sort { $a <=> $b } keys %expected;
  like(dies { proficiency_bonus(0) },  qr/level/, 'level 0 rejected');
  like(dies { proficiency_bonus(21) }, qr/level/, 'level 21 rejected');
  like(dies { proficiency_bonus(2.5) }, qr/level/, 'fraction rejected');
};

subtest 'tables' => sub {
  is(scalar @ABILITIES, 6, 'six abilities');
  is(scalar keys %SKILLS, 18, 'eighteen skills');
  is(skill_ability('stealth'), 'dexterity', 'stealth');
  is(skill_ability('animal handling'), 'wisdom', 'animal handling');
  like(dies { skill_ability('juggling') }, qr/unknown skill/, 'unknown skill');
  ok(is_ability('charisma') && !is_ability('luck'), 'is_ability');
  ok(is_skill('survival') && !is_skill('luck'), 'is_skill');
  is(scalar @SIZES, 6, 'six sizes');
  is($SPACE_FEET{Large}, 10, 'large space');
  is(scalar @DAMAGE_TYPES, 13, 'thirteen damage types');
  is(\@SENSES, [qw(blindsight darkvision tremorsense truesight)], 'senses');
};

done_testing;
