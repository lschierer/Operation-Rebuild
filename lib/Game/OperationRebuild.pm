package Game::OperationRebuild 0.001;

use v5.42.0;
use utf8::all;

# ABSTRACT: A post-collapse civilization rebuilding game with D&D-style mechanics

1;

__END__

=head1 SYNOPSIS

  # Play (graphical frontend; starts a local server if none is given):
  operation-rebuild
  operation-rebuild --server example.org:5400

  # Run a dedicated server with a text admin console:
  operation-rebuild-server --listen 127.0.0.1 --port 5400

=head1 DESCRIPTION

Operation Rebuild is a single- or multi-player strategy game set after the
collapse of a technological civilization. Genetic engineering produced
monstrous creatures, the infrastructure that industry depends on has failed,
and religion plays as large a part as technology in how people rebuild.
Units and monsters use a character-sheet model (ability scores, age
categories, size) derived from the D&D 5.2 System Reference Document.

This distribution is split into a frontend (C<bin/operation-rebuild>) and a
server (C<sbin/operation-rebuild-server>). All game rules live in modules under
C<Game::OperationRebuild::> that do not depend on SDL3, so they can be tested
without a display.

=head1 SEE ALSO

L<Game::OperationRebuild::Client>, L<Game::OperationRebuild::Server>,
L<Game::OperationRebuild::Dice>, L<Game::OperationRebuild::Random>.

The rules are derived in part from the System Reference Document 5.2.1,
copyright Wizards of the Coast LLC, licensed under CC-BY-4.0
(L<https://creativecommons.org/licenses/by/4.0/>).
