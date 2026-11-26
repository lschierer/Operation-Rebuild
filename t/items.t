use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Game::OperationRebuild::Currency;
use Game::OperationRebuild::Item;
use Game::OperationRebuild::Data;

my $C = 'Game::OperationRebuild::Currency';

subtest 'currency' => sub {
  is($C->parse('1 CP'), 1,      'copper');
  is($C->parse('5 SP'), 50,     'silver');
  is($C->parse('2 EP'), 100,    'electrum');
  is($C->parse('25 GP'), 2500,  'gold');
  is($C->parse('1 PP'), 1000,   'platinum');
  is($C->parse('1,000 GP'), 100000, 'commas');
  is($C->parse('2.5 GP'), 250,  'decimal');
  is($C->parse(' 3 gp '), 300,  'case and spaces');
  like(dies { $C->parse('2.555 GP') }, qr/whole number/, 'fractional copper rejected');
  like(dies { $C->parse('banana') },  qr/cannot parse/, 'junk rejected');
  like(dies { $C->parse('5 XX') },    qr/unknown coin/, 'unknown coin');
  like(dies { $C->parse(undef) },     qr/required/,     'undef');

  is($C->format(2500), '25 GP', 'format gold');
  is($C->format(50),   '5 SP',  'format silver');
  is($C->format(5),    '5 CP',  'format copper');
  is($C->format(250),  '25 SP',  'silver when gold does not divide evenly');
  is($C->format(255),  '255 CP', 'uneven amounts stay in copper');
  is($C->format(100000), '1,000 GP', 'thousands separator');
  is($C->format(0), '0 CP', 'zero');
};

sub make_item (%args) {
  Game::OperationRebuild::Item->from_hash({ id => 'x', name => 'X', category => 'gear', cost => '1 GP', %args });
}

my %DAGGER = (
  category => 'simple', kind => 'melee', damage => '1d4', damage_type => 'piercing',
  properties => [qw(finesse light thrown)], range => { normal => 20, long => 60 }, mastery => 'nick',
);

subtest 'item validation' => sub {
  my $i = make_item(cost => '25 GP', weight => 0.5);
  is($i->cost, 2500, 'cost in copper');
  is($i->cost_text, '25 GP', 'cost as text');
  is($i->weight, 0.5, 'weight');

  like(dies { make_item(colour => 'red') }, qr/unknown key.*colour/, 'unknown key');
  like(dies { make_item(category => 'treasure') }, qr/./, 'bad category');
  like(dies { make_item(id => 'Bad Id') }, qr/./, 'bad id');
  like(dies { make_item(cost => 'cheap') }, qr/cannot parse/, 'bad cost');
  like(dies { make_item(weight => -1) }, qr/./, 'negative weight');
  like(dies { make_item(category => 'weapon') }, qr/needs a weapon section/, 'weapon needs stats');
  like(dies { make_item(weapon => {%DAGGER}) }, qr/not a weapon/, 'stats need a weapon');
  like(dies { make_item(category => 'tool') }, qr/needs a tool section/, 'tool needs stats');
};

subtest 'weapon validation' => sub {
  my $w = sub (%o) { make_item(category => 'weapon', weapon => { %DAGGER, %o }) };
  ok(lives { $w->() }, 'valid dagger');
  like(dies { $w->(damage => 'lots') }, qr/not a dice expression/, 'bad damage');
  like(dies { $w->(damage_type => 'laser') }, qr/not a damage type/, 'bad damage type');
  like(dies { $w->(mastery => 'smash') }, qr/not a known mastery/, 'bad mastery');
  like(dies { $w->(properties => ['sharp']) }, qr/unknown property/, 'bad property');
  like(dies { $w->(kind => 'sideways') }, qr/melee or ranged/, 'bad kind');
  like(dies { $w->(category => 'exotic') }, qr/simple or martial/, 'bad category');
  like(dies { $w->(range => undef) }, qr/need a range/, 'thrown needs a range');
  like(dies { $w->(range => { normal => 60, long => 20 }) }, qr/range needs/, 'long range below normal');
  like(dies { $w->(versatile => '1d8') }, qr/needs the versatile property/, 'versatile damage needs property');
  like(dies { $w->(properties => ['versatile'], range => undef) }, qr/needs versatile damage/, 'property needs damage');
  like(dies { $w->(properties => [qw(ammunition)]) }, qr/ammunition type/, 'ammunition needs a type');
  like(dies { $w->(speed => 5) }, qr/unknown key.*speed/, 'unknown weapon key');
};

subtest 'tool validation' => sub {
  ok(lives { make_item(category => 'tool', tool => { ability => 'dexterity' }) }, 'valid tool');
  like(dies { make_item(category => 'tool', tool => { ability => 'luck' }) }, qr/not an ability/, 'bad ability');
  like(dies { make_item(category => 'tool', tool => { ability => 'wisdom', colour => 1 }) }, qr/unknown key.*colour/, 'unknown tool key');
};

subtest 'shipped items' => sub {
  my $data = Game::OperationRebuild::Data->new;
  my @ids = $data->item_ids;
  my @needed = qw(
    dagger quarterstaff spear shortbow arrows thieves-tools calligraphers-supplies
    healers-kit crowbar pouch travelers-clothes robe book parchment quiver
  );
  is([ grep { my $n = $_; !grep { $_ eq $n } @ids } @needed ], [], 'every item the three backgrounds need exists');

  my $dagger = $data->item('dagger');
  is($dagger->cost_text, '2 GP', 'dagger cost');
  is($dagger->weight, 1, 'dagger weight');
  is($dagger->weapon->{damage}, '1d4', 'dagger damage');
  is($dagger->weapon->{mastery}, 'nick', 'dagger mastery');

  my $staff = $data->item('quarterstaff');
  is($staff->weapon->{versatile}, '1d8', 'versatile damage');
  is($staff->cost, 20, 'quarterstaff 2 SP is 20 CP');

  my $bow = $data->item('shortbow');
  is($bow->weapon->{ammunition}, 'arrow', 'bow uses arrows');
  is($data->item('arrows')->bundle, 20, 'arrows come in twenties');
  is($data->item('healers-kit')->uses, 10, 'healer kit uses');
  is($data->item('thieves-tools')->tool->{ability}, 'dexterity', 'tool ability');

  is([ map { $_->id } $data->items_in_group('gaming-set') ],
    [qw(gaming-set-dice gaming-set-dragonchess gaming-set-playing-cards gaming-set-three-dragon-ante)],
    'four gaming sets');
  is([ $data->items_in_group('nonesuch') ], [], 'empty group');

  ok($data->item('dagger') == $data->item('dagger'), 'cached');
  like(dies { $data->item('../etc') }, qr/invalid item id/, 'path-like id rejected');
  like(dies { $data->item('nonesuch') }, qr/item not found/, 'unknown item');
};

subtest 'item files' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $idir = File::Spec->catdir($dir, 'data', 'items');
  make_path($idir);
  my $write = sub ($name, $text) {
    open my $fh, '>:encoding(UTF-8)', File::Spec->catfile($idir, "$name.yaml") or die $!;
    print {$fh} $text;
    close $fh;
  };

  $write->('a', "items:\n  - { id: rope, name: Rope, category: gear, cost: 1 GP, weight: 5 }\n");
  $write->('b', "items:\n  - { id: rope, name: Other Rope, category: gear, cost: 1 GP }\n");
  my $dup = Game::OperationRebuild::Data->new(share_dir => $dir);
  like(dies { $dup->item('rope') }, qr/duplicate item id 'rope'.*also in/s, 'duplicate across files');

  unlink File::Spec->catfile($idir, 'b.yaml');
  $write->('c', "things: []\n");
  like(dies { Game::OperationRebuild::Data->new(share_dir => $dir)->item('rope') }, qr/unknown key.*things/, 'unknown top-level key');

  unlink File::Spec->catfile($idir, 'c.yaml');
  $write->('d', "items:\n  - { id: bad, name: Bad, category: gear, cost: lots }\n");
  like(dies { Game::OperationRebuild::Data->new(share_dir => $dir)->item('rope') }, qr/invalid item in .*d\.yaml/s, 'error names the file');

  unlink File::Spec->catfile($idir, 'd.yaml');
  my $ok = Game::OperationRebuild::Data->new(share_dir => $dir);
  is($ok->item('rope')->cost_text, '1 GP', 'valid file loads');
  is([ $ok->item_ids ], ['rope'], 'ids');
};

done_testing;
