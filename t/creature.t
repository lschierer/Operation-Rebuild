use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Effect;
use Game::OperationRebuild::Trait;
use Game::OperationRebuild::Species;
use Game::OperationRebuild::Creature;

my %BASE = (
  strength => 15, dexterity => 14, constitution => 13,
  intelligence => 10, wisdom => 12, charisma => 8,
);

sub trait ($id, @effects) {
  return Game::OperationRebuild::Trait->from_hash({
    id => $id, name => ucfirst $id, channel => 'mutation', effects => [@effects],
  });
}

subtest 'effect validation' => sub {
  ok(lives { Game::OperationRebuild::Effect->new(kind => 'sense', target => 'darkvision', value => 60) }, 'valid');
  like(dies { Game::OperationRebuild::Effect->new(kind => 'sense', target => 'x-ray', value => 60) },
    qr/invalid target/, 'bad sense');
  like(dies { Game::OperationRebuild::Effect->new(kind => 'resistance', target => 'fire!') },
    qr/invalid target/, 'bad damage type');
  like(dies { Game::OperationRebuild::Effect->new(kind => 'teleport', target => 'x') },
    qr/./, 'unknown kind');
  like(dies { Game::OperationRebuild::Effect->new(kind => 'ability_score', target => 'strength', mode => 'multiply') },
    qr/./, 'unknown mode');
};

subtest 'trait validation' => sub {
  like(dies { Game::OperationRebuild::Trait->from_hash({ id => 'x', name => 'X', channel => 'mutation', colour => 'red' }) },
    qr/unknown key.*colour/, 'unknown key rejected');
  like(dies { Game::OperationRebuild::Trait->from_hash({ id => 'x', name => 'X', channel => 'magic' }) },
    qr/./, 'bad channel');
  my $deferred = Game::OperationRebuild::Trait->from_hash({
    id => 'smite', name => 'Smite', channel => 'faith', deferred => 1,
    effects => [ { kind => 'advantage', target => 'attack' } ],
  });
  is([ $deferred->active_effects ], [], 'deferred traits apply nothing');
};

subtest 'base statistics' => sub {
  my $c = Game::OperationRebuild::Creature->new(level => 1, abilities => {%BASE});
  is($c->ability_score('strength'), 15, 'score');
  is($c->ability_modifier_for('strength'), 2, 'modifier');
  is($c->proficiency_bonus, 2, 'proficiency bonus');
  is($c->skill_bonus('athletics'), 2, 'unproficient skill');
  is($c->size, 'Medium', 'default size');
  is($c->speed, 0, 'no species, no speed');
  is($c->sense_range('darkvision'), 0, 'no senses');
  is([ $c->resistances ], [], 'no resistances');
  like(dies { Game::OperationRebuild::Creature->new(abilities => { strength => 10 }) },
    qr/missing ability/, 'needs all abilities');
  like(dies { Game::OperationRebuild::Creature->new(level => 21, abilities => {%BASE}) },
    qr/./, 'level cap');
};

subtest 'proficiencies' => sub {
  my $c = Game::OperationRebuild::Creature->new(
    level => 5, abilities => {%BASE},
    skill_proficiencies => ['athletics'],
    save_proficiencies  => ['strength'],
    traits => [ trait('keen', { kind => 'skill_proficiency', target => 'perception' }) ],
  );
  is($c->skill_bonus('athletics'), 2 + 3, 'chosen proficiency');
  is($c->skill_bonus('perception'), 1 + 3, 'granted proficiency');
  is($c->skill_bonus('stealth'), 2, 'not proficient');
  is($c->save_bonus('strength'), 2 + 3, 'save proficiency');
  is($c->save_bonus('wisdom'), 1, 'save without proficiency');
  like(dies { Game::OperationRebuild::Creature->new(abilities => {%BASE}, skill_proficiencies => ['juggling']) },
    qr/unknown skill/, 'bad skill');
};

subtest 'ability score effects, caps and set' => sub {
  my $c = Game::OperationRebuild::Creature->new(
    abilities => { %BASE, strength => 19 },
    traits => [
      trait('a', { kind => 'ability_score', target => 'strength', value => 2 }),
      trait('b', { kind => 'ability_score', target => 'dexterity', value => 2 }),
      trait('c', { kind => 'ability_score', target => 'charisma', mode => 'set', value => 19 }),
      trait('d', { kind => 'ability_score', target => 'wisdom', mode => 'set', value => 8 }),
    ],
  );
  is($c->ability_score('strength'), 20, 'additive effects cap at 20');
  is($c->ability_score('dexterity'), 16, 'plain add');
  is($c->ability_score('charisma'), 19, 'set raises');
  is($c->ability_score('wisdom'), 12, 'set never lowers');
};

subtest 'speed, senses, resistances, advantage' => sub {
  my $c = Game::OperationRebuild::Creature->new(
    abilities => {%BASE},
    species => Game::OperationRebuild::Species->new(id => 'test', name => 'Test', size => 'Large', speed => 30),
    traits => [
      trait('fast', { kind => 'speed', target => 'walk', value => 10 }),
      trait('swim', { kind => 'speed', target => 'swim', mode => 'set', value => 20 }),
      trait('eyes', { kind => 'sense', target => 'darkvision', value => 60 }),
      trait('eyes2', { kind => 'sense', target => 'darkvision', value => 120 }),
      trait('skin', { kind => 'resistance', target => 'fire' }, { kind => 'resistance', target => 'cold' }),
      trait('skin2', { kind => 'resistance', target => 'fire' }),
      trait('brave', { kind => 'advantage', target => 'save:frightened' }),
      trait('clumsy', { kind => 'disadvantage', target => 'stealth' }),
    ],
  );
  is($c->size, 'Large', 'size from species');
  is($c->speed, 40, 'walk speed adds');
  is($c->speed('swim'), 20, 'swim speed set');
  is($c->speed('fly'), 0, 'no fly');
  is($c->sense_range('darkvision'), 120, 'largest range wins');
  is([ $c->resistances ], [ 'cold', 'fire' ], 'unique sorted resistances');
  ok($c->has_advantage('save:frightened'), 'advantage');
  ok(!$c->has_advantage('stealth'), 'no advantage');
  ok($c->has_disadvantage('stealth'), 'disadvantage');
};

subtest 'hit points' => sub {
  my $c = Game::OperationRebuild::Creature->new(level => 1, abilities => { %BASE, constitution => 14 }, hit_die => 12);
  is($c->max_hit_points, 12 + 2, 'level 1: die + con');

  my $c5 = Game::OperationRebuild::Creature->new(level => 5, abilities => { %BASE, constitution => 14 }, hit_die => 12);
  is($c5->max_hit_points, 14 + 4 * (7 + 2), 'level 5: average for later levels');

  my $tough = Game::OperationRebuild::Creature->new(
    level => 5, abilities => { %BASE, constitution => 14 }, hit_die => 12,
    traits => [ trait('tough', { kind => 'hit_points_per_level', target => 'max', value => 1 }) ],
  );
  is($tough->max_hit_points, 14 + 4 * 9 + 5, 'per-level bonus');

  my $frail = Game::OperationRebuild::Creature->new(level => 3, abilities => { %BASE, constitution => 1 }, hit_die => 4);
  is($frail->max_hit_points, 1 + 2 * 1, 'at least 1 per level');

  like(dies { Game::OperationRebuild::Creature->new(abilities => {%BASE})->max_hit_points },
    qr/hit_die/, 'needs hit die');
};

done_testing;
