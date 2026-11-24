use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Random;
use Game::OperationRebuild::Dice;
use Game::OperationRebuild::Roller;

sub roller ($seed) {
  Game::OperationRebuild::Roller->new(rng => Game::OperationRebuild::Random->new(seed => $seed));
}

subtest 'seeded and reproducible' => sub {
  my @a = map { roller(42)->roll('4d6kh3') } 1 .. 3;
  is($a[0], $a[1], 'same seed, same roll');
  my $one = roller(7);
  my $two = roller(7);
  is([ map { $one->roll('3d6+2') } 1 .. 20 ], [ map { $two->roll('3d6+2') } 1 .. 20 ], 'same sequence');
  my @other = map { roller(8)->roll('10d20') } 1;
  isnt(roller(7)->roll('10d20'), $other[0], 'different seed differs');
};

subtest 'uses our random source, in the same way as Dice' => sub {
  for my $seed (1, 2, 3, 99) {
    my $dice = Game::OperationRebuild::Dice->parse('3d6+2')->roll(Game::OperationRebuild::Random->new(seed => $seed));
    is(roller($seed)->roll('3d6+2'), $dice, "seed $seed matches Dice");
  }
};

subtest 'notation' => sub {
  my $r = roller(5);
  my $in_range = sub ($expr, $min, $max) {
    my @t = map { $r->roll($expr) } 1 .. 300;
    my ($lo, $hi) = (sort { $a <=> $b } @t)[ 0, -1 ];
    ok($lo >= $min && $hi <= $max, "$expr within $min..$max (saw $lo..$hi)");
  };
  $in_range->('d20', 1, 20);
  $in_range->('1d20+5', 6, 25);
  $in_range->('2d6-1', 1, 11);
  $in_range->('4d6kh3', 3, 18);
  $in_range->('4d6dl1', 3, 18);
  $in_range->('2d20kh1', 1, 20);

  is($r->roll_detail('d8')->{expression}, '1d8', 'bare d8 is normalised');
  is($r->roll_detail('4d6kh3 + 2')->{expression}, '4d6kh3+2', 'spaces removed, modifier kept');
  is($r->roll_detail('2d6 - 1')->{expression}, '2d6-1', 'negative modifier');
  ok(defined $r->roll_detail('4d6kh3')->{total}, 'total present');
};

subtest 'rejects unsupported expressions' => sub {
  for my $bad ('', 'banana', '3d6x6', '4d6r1', '3d6 4d6 kh', '1d1', '101d6', '1d1001', '2d6kh3', '3d6dl3', '3d6kh0', '4d6kh', '4d6kh3x') {
    like(dies { roller(1)->roll($bad) }, qr/./, "rejects '$bad'");
  }
  like(dies { roller(1)->roll(undef) }, qr/required/, 'undef rejected');
};

subtest 'advantage and disadvantage' => sub {
  my (@adv, @dis, @norm);
  my $r = roller(11);
  for (1 .. 2000) { push @adv, $r->d20('advantage'); push @dis, $r->d20('disadvantage'); push @norm, $r->d20 }
  my $mean = sub { my $t = 0; $t += $_ for @_; $t / @_ };
  ok($mean->(@adv) > $mean->(@norm) + 3, 'advantage averages higher');
  ok($mean->(@dis) < $mean->(@norm) - 3, 'disadvantage averages lower');
  is(roller(3)->d20('normal', 4), roller(3)->roll('1d20+4'), 'modifier applied');
  like(dies { roller(1)->d20('lucky') }, qr/unknown roll mode/, 'bad mode');
};

done_testing;
