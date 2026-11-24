package Game::OperationRebuild::Trait 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: A named feature carrying mechanics, an in-world explanation and a source

use Carp qw(croak);
use Game::OperationRebuild::Effect;

use constant CHANNELS => qw(training technique mutation faith);

my @KNOWN_KEYS = qw(
  id name channel explanation srd_source effects activation deferred
);

has param id      => (isa => StrMatch [qr/\A[a-z][a-z0-9-]*\z/]);
has param name    => (isa => NonEmptySimpleStr);
has param channel => (isa => Enum [CHANNELS]);
has param explanation => (isa => Str, default => '');
has option srd_source => (isa => Str);

has param effects => (
  isa     => ArrayRef [ InstanceOf ['Game::OperationRebuild::Effect'] ],
  default => sub { [] },
);

# Abilities the player activates (uses, recharge, duration). Stored as data;
# the rules engine for activation does not exist yet.
has option activation => (isa => HashRef);

# Deferred traits are kept in the data but have no effect yet.
has param deferred => (isa => Bool, default => 0);

sub active_effects ($self) {
  return () if $self->deferred;
  return $self->effects->@*;
}

sub from_hash ($class, $data) {
  croak "trait data must be a hash" unless ref $data eq 'HASH';
  my %known = map { $_ => 1 } @KNOWN_KEYS;
  my @bad   = grep { !$known{$_} } sort keys %$data;
  croak "unknown key(s) in trait '" . ($data->{id} // '?') . "': @bad" if @bad;

  my %args = %$data;
  $args{effects} = [
    map { Game::OperationRebuild::Effect->new(%$_) } ($data->{effects} // [])->@*
  ];
  $args{deferred} = $data->{deferred} ? 1 : 0;
  return $class->new(%args);
}

1;

__END__

=head1 SYNOPSIS

  my $trait = Game::OperationRebuild::Trait->from_hash({
    id          => 'darkvision-dwarf',
    name        => 'Darkvision',
    channel     => 'mutation',
    explanation => 'Enlarged eyes from generations bred for tunnel work.',
    srd_source  => 'Darkvision',
    effects     => [ { kind => 'sense', target => 'darkvision', value => 120 } ],
  });

=head1 DESCRIPTION

A trait separates three things. Its I<mechanics> are the effects. Its
I<explanation> says how it works in this world and can be rewritten freely.
Its I<srd_source> names the System Reference Document feature it adapts, so
attribution stays accurate. See F<doc/rules-adaptation.md>.

=attr id

Lower case identifier with digits and hyphens.

=attr name

Display name.

=attr channel

Where the ability comes from: C<training>, C<technique>, C<mutation> or
C<faith>.

=attr explanation

In-world description.

=attr srd_source

Name of the adapted SRD feature, if any.

=attr effects

List of L<Game::OperationRebuild::Effect> objects.

=attr activation

Free-form data for player-activated abilities. Not yet interpreted.

=attr deferred

True when the trait is kept in the data but not yet applied.

=method active_effects

The effects to apply (none when deferred).

=method from_hash

Builds a trait, and its effects, from plain data such as parsed YAML. Dies on
unknown keys.
