use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::AbilityScores;
use Game::OperationRebuild::Random;
use Game::OperationRebuild::Roller;
use Game::OperationRebuild::Rules qw(@ABILITIES);

my $AS = 'Game::OperationRebuild::AbilityScores';

subtest 'standard array' => sub {
  is([ $AS->standard_array ], [ 15, 14, 13, 12, 10, 8 ], 'values');
  my $scores = $AS->assign_standard_array([ 8, 10, 12, 13, 14, 15 ], [qw(strength dexterity constitution intelligence wisdom charisma)]);
  is($scores->{strength}, 8, 'assigned in given order');
  is($scores->{charisma}, 15, 'last one');
  like(dies { $AS->assign_standard_array([ 16, 14, 13, 12, 10, 8 ], \@ABILITIES) }, qr/not the standard array/, 'must be the array');
};

subtest 'assign' => sub {
  like(dies { $AS->assign([ 1 .. 5 ], \@ABILITIES) }, qr/six scores/, 'six values');
  like(dies { $AS->assign([ 10 .. 15 ], [qw(strength strength dexterity wisdom charisma intelligence)]) }, qr/twice/, 'duplicate ability');
  like(dies { $AS->assign([ 10 .. 15 ], [qw(strength luck dexterity wisdom charisma intelligence)]) }, qr/unknown ability/, 'unknown ability');
};

subtest 'point buy' => sub {
  is($AS->point_cost($_), (0, 1, 2, 3, 4, 5, 7, 9)[ $_ - 8 ], "cost of $_") for 8 .. 15;
  like(dies { $AS->point_cost(16) }, qr/no point cost/, '16 not allowed');
  like(dies { $AS->point_cost(7) },  qr/no point cost/, '7 not allowed');

  my %classic = (strength => 15, dexterity => 14, constitution => 13, intelligence => 12, wisdom => 10, charisma => 8);
  is($AS->points_spent(\%classic), 9 + 7 + 5 + 4 + 2 + 0, 'cost adds up');
  is($AS->validate_point_buy(\%classic), \%classic, 'exactly 27 is valid');

  my %all8 = map { $_ => 8 } @ABILITIES;
  ok(lives { $AS->validate_point_buy(\%all8) }, 'spending nothing is valid');

  my %over = (%classic, wisdom => 15);
  like(dies { $AS->validate_point_buy(\%over) }, qr/spends 34 points/, 'over budget');
  my %missing = %classic; delete $missing{charisma};
  like(dies { $AS->validate_point_buy(\%missing) }, qr/missing ability/, 'missing ability');
  like(dies { $AS->validate_point_buy({ %classic, luck => 8 }) }, qr/unknown abilities/, 'extra ability');
};

subtest 'random generation' => sub {
  my $make = sub ($seed) { Game::OperationRebuild::Roller->new(rng => Game::OperationRebuild::Random->new(seed => $seed)) };
  my @set = $AS->roll_set($make->(42));
  is(scalar @set, 6, 'six scores');
  ok((grep { $_ < 3 || $_ > 18 } @set) == 0, "all within 3..18: @set");
  is(\@set, [ sort { $b <=> $a } @set ], 'highest first');
  is([ $AS->roll_set($make->(42)) ], \@set, 'reproducible from the seed');
  isnt([ $AS->roll_set($make->(43)) ], \@set, 'different seed differs');

  # Rolling 4d6 and keeping three averages about 12.24, above the 10.5 of 3d6.
  my $roller = $make->(2024);
  my @all = map { $AS->roll_set($roller) } 1 .. 300;
  my $mean = 0; $mean += $_ for @all; $mean /= @all;
  ok($mean > 11.8 && $mean < 12.7, sprintf('mean %.2f is near 12.24', $mean));
};

done_testing;
