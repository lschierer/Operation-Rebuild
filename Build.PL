use v5.42.0;
use utf8::all;
use lib 'inc';
use ORBuild::Builder;

# In a git checkout weaver.ini exists and POD is woven at build time. The
# release tarball ships already-woven POD and omits weaver.ini, so installing
# from CPAN does not need Pod::Weaver.
my $weaving = -e 'weaver.ini';

my $build = ORBuild::Builder->new(
  module_name       => 'Game::OperationRebuild',
  dist_name         => 'Game-OperationRebuild',
  dist_version_from => 'lib/Game/OperationRebuild.pm',
  dist_abstract     => 'A post-collapse civilization rebuilding game with D&D-style mechanics',
  dist_author       => ['Luke Schierer'],

  # Code is ISC; game content in share/ is CC-BY-4.0 (see LICENSE). Module::Build
  # and CPAN::Meta have no 'isc' value, so the metadata says open_source and
  # names the license in resources below.
  license => 'open_source',

  # The frontend (bin/) and the game server (sbin/) both install as scripts.
  script_files => [ 'bin/operation-rebuild', 'sbin/operation-rebuild-server' ],
  share_dir    => 'share',

  configure_requires => {
    'Module::Build' => '0.4234',
    'perl'          => 'v5.42.0',
  },
  requires => {
    'perl'            => 'v5.42.0',
    'File::ShareDir'  => 0,
    # Needs the rand option and keep/drop notation submitted upstream; the
    # released 1.2 lacks them (Roller checks and explains; see INSTALL).
    'Games::Dice::Advanced' => '1.2',
    'Getopt::Long'    => 0,
    'Mooish::Base'    => 0,
    'SDL3'            => 0,
    'utf8::all'       => 0,
    'YAML::PP'        => 0,
  },
  build_requires => {
    'Module::Build' => '0.4234',
    'Path::Tiny'    => 0,
    ( $weaving
      ? (
        'PPI'              => 0,
        'Pod::Elemental'   => 0,
        'Pod::Weaver'      => 0,
        'Software::License' => 0,
      )
      : () ),
  },
  test_requires => {
    'Test2::V1' => 0,
  },
  recommends => {
    'Perl::Critic' => 0,
    'Test::Pod'    => 0,
  },

  meta_merge => {
    resources => {
      license    => ['https://opensource.org/license/isc-license-txt'],
      repository => 'https://github.com/lschierer/Operation-Rebuild',
      bugtracker => 'https://github.com/lschierer/Operation-Rebuild/issues',
    },
  },
  create_license => 0,
);

$build->create_build_script;
