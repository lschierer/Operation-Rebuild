package Game::OperationRebuild::Share 0.001;

use v5.42.0;
use utf8::all;

# ABSTRACT: Locate the directory holding game data files

use Carp qw(croak);
use File::Basename qw(dirname);
use File::ShareDir ();
use File::Spec;

use constant DIST_NAME => 'Game-OperationRebuild';

# Order of preference:
#   1. $OPERATION_REBUILD_SHARE, for testing and unusual layouts;
#   2. share/ of a source checkout (found by Build.PL beside lib/);
#   3. the installed or built (blib) File::ShareDir location.
sub share_dir () {
  my $override = $ENV{OPERATION_REBUILD_SHARE};
  if (defined $override && length $override) {
    croak "OPERATION_REBUILD_SHARE is not a directory: $override" unless -d $override;
    return $override;
  }

  # lib/Game/OperationRebuild/Share.pm -> repository root is four levels up.
  my $root = File::Spec->rel2abs(dirname(dirname(dirname(dirname(__FILE__)))));
  my $dev  = File::Spec->catdir($root, 'share');
  return $dev if -f File::Spec->catfile($root, 'Build.PL') && -d $dev;

  return File::ShareDir::dist_dir(DIST_NAME);
}

1;

__END__

=head1 SYNOPSIS

  use Game::OperationRebuild::Share;
  my $dir = Game::OperationRebuild::Share::share_dir();

=head1 DESCRIPTION

Game data (YAML rule tables, sprites, sounds) lives in F<share/>. This module
finds it whether the code runs from a git checkout, from F<blib/> during
C<./Build test>, or from an installation.

=head1 FUNCTIONS

=head2 share_dir

Returns the directory path. Dies if C<OPERATION_REBUILD_SHARE> is set to
something that is not a directory, or if no share directory can be found.
