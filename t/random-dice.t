use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Random;
use Game::OperationRebuild::Dice;

subtest 'same seed, same sequence' => sub {
  my $a = Game::OperationRebuild::Random->new(seed => 42);
  my $b = Game::OperationRebuild::Random->new(seed => 42);
  my @a = map { $a->next_float } 1 .. 20;
  my @b = map { $b->next_float } 1 .. 20;
  is(\@a, \@b, 'identical');
  ok((grep { $_ < 0 || $_ >= 1 } @a) == 0, 'all values in [0,1)');

  my $c = Game::OperationRebuild::Random->new(seed => 43);
  isnt([ map { $c->next_float } 1 .. 20 ], \@a, 'different seed differs');
};

subtest 'matches perl drand48' => sub {
  srand(42);
  my @perl = map { rand } 1 .. 5;
  my $rng  = Game::OperationRebuild::Random->new(seed => 42);
  my @ours = map { $rng->next_float } 1 .. 5;
  is(\@ours, \@perl, 'same as srand/rand');
};

subtest 'int_between' => sub {
  my $rng = Game::OperationRebuild::Random->new(seed => 1);
  my %seen;
  $seen{ $rng->int_between(1, 6) }++ for 1 .. 600;
  is([ sort keys %seen ], [1 .. 6], 'covers 1..6 exactly');
  like(dies { $rng->int_between(5, 1) }, qr/greater than/, 'rejects bad range');
};

subtest 'dice parsing' => sub {
  my $d = Game::OperationRebuild::Dice->parse('2d6+3');
  is([ $d->count, $d->sides, $d->modifier ], [ 2, 6, 3 ], '2d6+3');
  is($d->to_string, '2d6+3', 'round trip');
  is(Game::OperationRebuild::Dice->parse('d20')->to_string, '1d20', 'd20');
  is(Game::OperationRebuild::Dice->parse('1d4 - 1')->modifier, -1, 'negative');
  like(dies { Game::OperationRebuild::Dice->parse('banana') }, qr/Cannot parse/, 'bad text');
};

subtest 'dice rolling' => sub {
  my $d   = Game::OperationRebuild::Dice->parse('3d6+1');
  my $rng = Game::OperationRebuild::Random->new(seed => 9);
  is([ $d->minimum, $d->maximum ], [ 4, 19 ], 'bounds');
  my @totals = map { $d->roll($rng) } 1 .. 200;
  ok((grep { $_ < 4 || $_ > 19 } @totals) == 0, 'within bounds');

  my $one = Game::OperationRebuild::Random->new(seed => 5);
  my $two = Game::OperationRebuild::Random->new(seed => 5);
  is($d->roll($one), $d->roll($two), 'reproducible');
};

done_testing;
