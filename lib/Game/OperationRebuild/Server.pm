package Game::OperationRebuild::Server 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Game server with a text administration console

use Getopt::Long qw(GetOptionsFromArray);

use constant DEFAULT_LISTEN => '127.0.0.1';
use constant DEFAULT_PORT   => 5400;

with 'Game::OperationRebuild::Role::Debuggable';

has param listen => (isa => Str, default => DEFAULT_LISTEN, writer => 1);
has param port   => (isa => PositiveInt, default => DEFAULT_PORT, writer => 1);

sub usage ($self) {
  return <<~'USAGE';
    Usage: operation-rebuild-server [--listen ADDRESS] [--port PORT] [--debug[=SEED]]
           operation-rebuild-server --version | --help
    USAGE
}

# Entry point used by sbin/operation-rebuild-server. Returns the exit code.
sub run ($self, @args) {
  my %opt;
  Getopt::Long::Configure('no_ignore_case');
  GetOptionsFromArray(
    \@args, \%opt,
    'help|h', 'version|V', 'listen|l=s', 'port|p=i', 'debug:s',
  ) or do { warn $self->usage; return 2 };

  if ($opt{help}) { print $self->usage; return 0 }
  if ($opt{version}) {
    say "operation-rebuild-server ", Game::OperationRebuild::Server->VERSION;
    return 0;
  }

  eval {
    $self->set_debug_from_option($opt{debug}) if exists $opt{debug};
    $self->set_listen($opt{listen}) if defined $opt{listen};
    $self->set_port($opt{port})     if defined $opt{port};
    1;
  } or do { warn $@; return 2 };

  # Listening for clients and the admin console are not written yet.
  warn "The server is not implemented yet.\n";
  return 1;
}

1;

__END__

=head1 SYNOPSIS

  use Game::OperationRebuild::Server;
  exit Game::OperationRebuild::Server->new->run(@ARGV);

=head1 DESCRIPTION

The game server. It will listen for clients (on localhost unless told
otherwise) and provide a text console for administration commands, in the
manner of the freeciv server. The game itself is not played on that console.

=attr listen

Address to listen on, default C<127.0.0.1>.

=attr port

TCP port to listen on, default 5400.

=method run

C<< $server->run(@ARGV) >> processes arguments and returns an exit code.

=method usage

Returns the usage text.
