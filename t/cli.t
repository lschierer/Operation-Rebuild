use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

use Game::OperationRebuild::Client;
use Game::OperationRebuild::Server;

subtest 'debug seed handling' => sub {
  my $c = Game::OperationRebuild::Client->new;
  ok(!$c->is_debug, 'not debugging by default');

  $c->set_debug_from_option('');
  is($c->debug_seed, 42, '--debug alone uses default seed');

  $c->set_debug_from_option('1234');
  is($c->debug_seed, 1234, '--debug=1234');

  like(dies { $c->set_debug_from_option('abc') }, qr/integer seed/, 'rejects junk');

  my $a = $c->make_rng;
  my $b = $c->make_rng;
  is($a->next_float, $b->next_float, 'debug rng is deterministic');
};

subtest 'client run' => sub {
  my $out = '';
  {
    open my $fh, '>', \$out or die;
    local *STDOUT = $fh;
    is(Game::OperationRebuild::Client->new->run('--version'), 0, '--version exits 0');
  }
  like($out, qr/^operation-rebuild 0\.001$/, 'prints version');

  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  is(Game::OperationRebuild::Client->new->run('--bogus'), 2, 'unknown option exits 2');
  is(Game::OperationRebuild::Client->new->run('--debug=x'), 2, 'bad seed exits 2');
};

subtest 'server defaults' => sub {
  my $s = Game::OperationRebuild::Server->new;
  is([ $s->listen, $s->port ], [ '127.0.0.1', 5400 ], 'listens on localhost');
};

done_testing;
