use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Game::OperationRebuild::Data;
use Game::OperationRebuild::Creature;

my %BASE = (
  strength => 15, dexterity => 14, constitution => 14,
  intelligence => 10, wisdom => 12, charisma => 8,
);

subtest 'shipped dwarf data' => sub {
  my $data = Game::OperationRebuild::Data->new;
  ok(-d $data->root, 'share directory found: ' . $data->root);
  ok((grep { $_ eq 'dwarf' } $data->species_ids), 'dwarf listed');

  my $dwarf = $data->species('dwarf');
  is($dwarf->name, 'Dwarf', 'name');
  is($dwarf->size, 'Medium', 'size');
  is($dwarf->speed, 30, 'speed');
  ok($dwarf == $data->species('dwarf'), 'cached');
  ok((grep { $_->srd_source } $dwarf->traits->@*) == $dwarf->traits->@*, 'every trait records its SRD source');

  my $creature = Game::OperationRebuild::Creature->new(
    level => 3, abilities => {%BASE}, species => $dwarf, hit_die => 12,
  );
  is($creature->sense_range('darkvision'), 120, 'darkvision');
  is([ $creature->resistances ], ['poison'], 'poison resistance');
  ok($creature->has_advantage('save:poisoned'), 'advantage against poison');
  is($creature->speed, 30, 'speed');
  is($creature->max_hit_points, 14 + 2 * (7 + 2) + 3, 'dwarven toughness adds 1 per level');
  is($creature->sense_range('tremorsense'), 0, 'stonecunning is activated, not constant');
};

subtest 'bad ids and files' => sub {
  my $data = Game::OperationRebuild::Data->new;
  like(dies { $data->species('../dwarf') }, qr/invalid species id/, 'path traversal rejected');
  like(dies { $data->species('Dwarf') },    qr/invalid species id/, 'upper case rejected');
  like(dies { $data->species('') },         qr/invalid species id/, 'empty rejected');
  like(dies { $data->species('nonesuch') }, qr/not found/, 'missing file');

  my $dir = tempdir(CLEANUP => 1);
  my $sdir = File::Spec->catdir($dir, 'data', 'species');
  make_path($sdir);
  my $write = sub ($name, $text) {
    open my $fh, '>:encoding(UTF-8)', File::Spec->catfile($sdir, "$name.yaml") or die $!;
    print {$fh} $text;
    close $fh;
  };

  $write->('broken', "id: broken\nname: [unclosed\n");
  $write->('mismatch', "id: other\nname: Other\n");
  $write->('typo', "id: typo\nname: Typo\ncolour: red\n");
  $write->('badeffect', <<~'YAML');
    id: badeffect
    name: Bad Effect
    traits:
      - id: x
        name: X
        channel: mutation
        effects:
          - { kind: sense, target: x-ray, value: 60 }
    YAML
  $write->('good', "id: good\nname: Good\ntraits: []\n");

  my $tmp = Game::OperationRebuild::Data->new(share_dir => $dir);
  like(dies { $tmp->species('broken') },    qr/cannot parse.*broken\.yaml/s, 'syntax error names the file');
  like(dies { $tmp->species('mismatch') },  qr/does not match file name/, 'id must match file');
  like(dies { $tmp->species('typo') },      qr/invalid species data.*unknown key.*colour/s, 'unknown key');
  like(dies { $tmp->species('badeffect') }, qr/invalid target/, 'invalid effect target');
  is($tmp->species('good')->name, 'Good', 'valid file loads');
  is([ $tmp->species_ids ], [ qw(badeffect broken good mismatch typo) ], 'ids listed');
};

done_testing;
