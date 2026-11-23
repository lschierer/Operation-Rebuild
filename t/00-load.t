use v5.42.0;
use utf8::all;
use Test2::V1 -ipP;

my @modules = qw(
  Game::OperationRebuild
  Game::OperationRebuild::Random
  Game::OperationRebuild::Dice
  Game::OperationRebuild::Role::Debuggable
  Game::OperationRebuild::Client
  Game::OperationRebuild::Server
);

for my $module (@modules) {
  ok(lives { require_module($module) }, "$module loads") or diag $@;
}

sub require_module ($module) {
  (my $file = "$module.pm") =~ s{::}{/}g;
  require $file;
}

done_testing;
