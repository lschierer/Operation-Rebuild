package Game::OperationRebuild::Species 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: A species (an engineered or diverged line) and its traits

use Carp qw(croak);
use Game::OperationRebuild::Rules qw(@SIZES);
use Game::OperationRebuild::Trait;

my @KNOWN_KEYS = qw(id name srd_source creature_type size speed explanation traits);

has param id   => (isa => StrMatch [qr/\A[a-z][a-z0-9-]*\z/]);
has param name => (isa => NonEmptySimpleStr);
has option srd_source => (isa => Str);
has param creature_type => (isa => Str, default => 'Humanoid');
has param size  => (isa => Enum [@SIZES], default => 'Medium');
has param speed => (isa => PositiveInt, default => 30);
has param explanation => (isa => Str, default => '');

has param traits => (
  isa     => ArrayRef [ InstanceOf ['Game::OperationRebuild::Trait'] ],
  default => sub { [] },
);

sub from_hash ($class, $data) {
  croak "species data must be a hash" unless ref $data eq 'HASH';
  my %known = map { $_ => 1 } @KNOWN_KEYS;
  my @bad   = grep { !$known{$_} } sort keys %$data;
  croak "unknown key(s) in species '" . ($data->{id} // '?') . "': @bad" if @bad;

  my %args = %$data;
  $args{traits} = [ map { Game::OperationRebuild::Trait->from_hash($_) } ($data->{traits} // [])->@* ];

  my %seen;
  for my $trait ($args{traits}->@*) {
    croak "duplicate trait id '" . $trait->id . "' in species '$data->{id}'"
      if $seen{ $trait->id }++;
  }
  return $class->new(%args);
}

1;

__END__

=head1 SYNOPSIS

  my $species = Game::OperationRebuild::Species->from_hash(
    YAML::PP->new->load_file('share/data/species/dwarf.yaml')
  );

=head1 DESCRIPTION

A species supplies a creature's size, base walking speed and a set of
traits. The SRD species give no ability score bonuses and no lifespan; those
come from backgrounds and from our own rules respectively.

=attr id

Lower case identifier, also the data file name.

=attr name

Display name.

=attr srd_source

Name of the SRD species this adapts.

=attr creature_type

Defaults to C<Humanoid>.

=attr size

One of the sizes in L<Game::OperationRebuild::Rules>; default C<Medium>.

=attr speed

Walking speed in feet, default 30.

=attr explanation

In-world description of the line.

=attr traits

List of L<Game::OperationRebuild::Trait> objects.

=method from_hash

Builds a species from plain data. Dies on unknown keys or duplicate trait ids.
