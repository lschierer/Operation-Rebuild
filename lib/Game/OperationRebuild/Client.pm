package Game::OperationRebuild::Client 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Graphical frontend entry point

use Getopt::Long qw(GetOptionsFromArray);

with 'Game::OperationRebuild::Role::Debuggable';

has option server => (
  isa    => Str,
  writer => 1,
);

sub usage ($self) {
  return <<~'USAGE';
    Usage: operation-rebuild [--server HOST[:PORT]] [--debug[=SEED]]
           operation-rebuild --version | --help
    USAGE
}

# Entry point used by bin/operation-rebuild. Returns the process exit code.
sub run ($self, @args) {
  my %opt;
  Getopt::Long::Configure('no_ignore_case');
  GetOptionsFromArray(
    \@args, \%opt,
    'help|h', 'version|V', 'server|s=s', 'debug:s',
  ) or do { warn $self->usage; return 2 };

  if ($opt{help}) { print $self->usage; return 0 }
  if ($opt{version}) {
    say "operation-rebuild ", Game::OperationRebuild::Client->VERSION;
    return 0;
  }

  eval {
    $self->set_debug_from_option($opt{debug}) if exists $opt{debug};
    1;
  } or do { warn $@; return 2 };
  $self->set_server($opt{server}) if defined $opt{server};

  # The SDL3 user interface is not written yet.
  warn "The graphical interface is not implemented yet.\n";
  return 1;
}

1;

__END__

=head1 SYNOPSIS

  use Game::OperationRebuild::Client;
  exit Game::OperationRebuild::Client->new->run(@ARGV);

=head1 DESCRIPTION

The graphical frontend. It parses the command line and will start the SDL3
user interface, connecting to the server given by C<--server> or starting a
local one for single-player games. It consumes
L<Game::OperationRebuild::Role::Debuggable> for C<--debug>.

=attr server

Optional C<host[:port]> of the server to join.

=method run

C<< $client->run(@ARGV) >> processes arguments and returns an exit code.

=method usage

Returns the usage text.
