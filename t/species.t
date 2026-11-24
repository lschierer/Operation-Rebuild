use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Data;
use Game::OperationRebuild::Creature;
use Game::OperationRebuild::Rules qw(%SKILLS);

my $data = Game::OperationRebuild::Data->new;

my %BASE = (
  strength => 15, dexterity => 14, constitution => 14,
  intelligence => 10, wisdom => 12, charisma => 8,
);

# Answer every choice with its first option(s), or with explicit picks.
sub creature_for ($id, %args) {
  my $species = $data->species($id);
  my %picks = ($args{choices} // {})->%*;
  for my $choice ($species->choices->@*) {
    $picks{ $choice->id } //= [ map { $_->id } $choice->options->@[ 0 .. $choice->pick - 1 ] ];
  }
  return Game::OperationRebuild::Creature->new(
    level => $args{level} // 1, abilities => {%BASE}, species => $species,
    choices => \%picks, hit_die => 8,
  );
}

subtest 'all seven species load' => sub {
  is([ $data->species_ids ], [qw(dwarf elf gnome goliath halfling human orc)], 'ids');
  for my $id ($data->species_ids) {
    my $s = $data->species($id);
    ok(defined $s->srd_source, "$id records its SRD source");
    my @traits = ($s->traits->@*, map { $_->options->@* } $s->choices->@*);
    my @missing = grep { !defined $_->srd_source } @traits;
    is(\@missing, [], "$id: every trait and option records its SRD source");
    ok(lives { creature_for($id) }, "$id: a creature can be built");
  }
};

subtest 'sizes and speeds' => sub {
  is(creature_for($_->[0])->size, $_->[1], "$_->[0] size") for ([ dwarf => 'Medium' ], [ gnome => 'Small' ],
    [ halfling => 'Small' ], [ goliath => 'Medium' ], [ elf => 'Medium' ]);
  is(creature_for('goliath')->speed, 35, 'goliath speed');
  is(creature_for('dwarf')->speed, 30, 'dwarf speed');
};

subtest 'senses' => sub {
  is(creature_for('elf', choices => { 'elven-lineage' => ['high-elf'] })->sense_range('darkvision'), 60, 'elf');
  is(creature_for('gnome')->sense_range('darkvision'), 60, 'gnome');
  is(creature_for('orc')->sense_range('darkvision'), 120, 'orc');
  is(creature_for('dwarf')->sense_range('darkvision'), 120, 'dwarf');
  is(creature_for('halfling')->sense_range('darkvision'), 0, 'halfling has none');
  is(creature_for('goliath')->sense_range('darkvision'), 0, 'goliath has none');
};

subtest 'elf choices and levels' => sub {
  my $drow = creature_for('elf', choices => { 'elven-lineage' => ['drow'], 'keen-senses' => ['keen-survival'] });
  is($drow->sense_range('darkvision'), 120, 'drow darkvision');
  ok($drow->skill_proficient('survival'), 'keen senses survival');
  ok(!$drow->skill_proficient('perception'), 'only the chosen skill');
  ok($drow->has_advantage('save:charmed'), 'fey ancestry');
  is([ map { $_->{name} } $drow->activations ], [ 'Trance', 'Bioluminescent Display' ], 'level 1 abilities');

  my $drow5 = creature_for('elf', level => 5, choices => { 'elven-lineage' => ['drow'] });
  is([ sort map { $_->{name} } $drow5->activations ],
    [ 'Bioluminescent Display', 'Luminous Marking', 'Spore Cloud', 'Trance' ], 'level 5 abilities');

  my $wood = creature_for('elf', choices => { 'elven-lineage' => ['wood-elf'] });
  is($wood->speed, 35, 'wood elf speed');
  is($wood->sense_range('darkvision'), 60, 'wood elf keeps normal darkvision');
};

subtest 'choice validation' => sub {
  my $elf = $data->species('elf');
  my %ok = ('keen-senses' => ['keen-insight'], 'elven-lineage' => ['drow']);
  my $build = sub (%c) {
    Game::OperationRebuild::Creature->new(abilities => {%BASE}, species => $elf, choices => {%ok, %c});
  };
  ok(lives { $build->() }, 'valid selection');
  like(dies { $build->('elven-lineage' => ['nonesuch']) }, qr/no option/, 'unknown option');
  like(dies { $build->('elven-lineage' => ['drow', 'high-elf']) }, qr/needs 1 selection/, 'too many');
  like(dies { $build->('elven-lineage' => []) }, qr/needs 1 selection/, 'too few');
  like(dies { $build->(surprise => ['x']) }, qr/unknown choice/, 'unknown choice');
  like(dies { Game::OperationRebuild::Creature->new(abilities => {%BASE}, species => $elf) },
    qr/needs 1 selection/, 'choices are required');
};

subtest 'goliath' => sub {
  my ($ancestry) = grep { $_->id eq 'giant-ancestry' } $data->species('goliath')->choices->@*;
  is([ map { $_->id } $ancestry->options->@* ], [qw(cloud hill stone storm)], 'giant ancestries offered');
  my $g = creature_for('goliath', choices => { 'giant-ancestry' => ['storm'] });
  ok($g->has_advantage('check:end-grappled'), 'powerful build');
  ok($g->has_flag('carry:counts-as-larger'), 'carrying flag');
  is([ map { $_->{name} } $g->activations ], ["Storm's Thunder"], 'only the chosen ancestry');
  my $g5 = creature_for('goliath', level => 5, choices => { 'giant-ancestry' => ['stone'] });
  is([ sort map { $_->{name} } $g5->activations ], [ 'Large Form', "Stone's Endurance" ], 'large form at 5');
};

subtest 'halfling and orc flags and abilities' => sub {
  my $h = creature_for('halfling');
  ok($h->has_advantage('save:frightened'), 'brave');
  ok($h->has_flag('luck:reroll-natural-1'), 'luck');
  ok($h->has_flag('move:through-larger-creatures'), 'nimbleness');
  ok(!creature_for('human')->has_flag('luck:reroll-natural-1'), 'only halflings');
  my $o = creature_for('orc');
  is([ sort map { $_->{name} } $o->activations ], [ 'Adrenaline Rush', 'Relentless Endurance' ], 'orc abilities');
};

subtest 'human skillful' => sub {
  my $choice = $data->species('human')->choices->[0];
  is(scalar $choice->options->@*, scalar keys %SKILLS, 'one option per skill');
  my $h = creature_for('human', choices => { skillful => ['skillful-sleight-of-hand'] });
  ok($h->skill_proficient('sleight of hand'), 'chosen skill');
  ok(!$h->skill_proficient('stealth'), 'others not');
  is([ map { $_->{name} } $h->activations ], ['Resourceful'], 'resourceful');
  is(scalar(grep { $_->id eq 'versatile' } $h->all_traits), 1, 'deferred trait is kept');
  is([ grep { $_->kind eq 'ability_score' } $h->effects ], [], 'no ability bonuses from species');
};

done_testing;
