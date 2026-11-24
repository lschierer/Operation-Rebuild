package Game::OperationRebuild::Choice 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: A decision between traits offered by a species

use Carp qw(croak);
use Game::OperationRebuild::Rules qw(%SKILLS);
use Game::OperationRebuild::Trait;

my @KNOWN_KEYS = qw(id name pick channel srd_source options options_from);

has param id   => (isa => StrMatch [qr/\A[a-z][a-z0-9-]*\z/]);
has param name => (isa => NonEmptySimpleStr);
has param pick => (isa => PositiveInt, default => 1);

has param options => (
  isa => ArrayRef [ InstanceOf ['Game::OperationRebuild::Trait'] ],
);

sub find_option ($self, $id) {
  my ($found) = grep { $_->id eq $id } $self->options->@*;
  return $found;
}

# Options may be written out as traits, or generated: "options_from: skills"
# offers one skill proficiency per SRD skill.
sub from_hash ($class, $data) {
  croak "choice data must be a hash" unless ref $data eq 'HASH';
  my %known = map { $_ => 1 } @KNOWN_KEYS;
  my @bad   = grep { !$known{$_} } sort keys %$data;
  croak "unknown key(s) in choice '" . ($data->{id} // '?') . "': @bad" if @bad;
  croak "choice '" . ($data->{id} // '?') . "' needs exactly one of options or options_from"
    unless defined $data->{options} xor defined $data->{options_from};

  my @options;
  if (defined $data->{options}) {
    @options = map { Game::OperationRebuild::Trait->from_hash($_) } $data->{options}->@*;
  }
  else {
    croak "unknown options_from '$data->{options_from}'" unless $data->{options_from} eq 'skills';
    for my $skill (sort keys %SKILLS) {
      (my $slug = $skill) =~ s/ /-/g;
      push @options, Game::OperationRebuild::Trait->new(
        id         => "$data->{id}-$slug",
        name       => join(' ', map { ucfirst } split / /, $skill),
        channel    => $data->{channel} // 'technique',
        ($data->{srd_source} ? (srd_source => $data->{srd_source}) : ()),
        effects    => [
          Game::OperationRebuild::Effect->new(kind => 'skill_proficiency', target => $skill),
        ],
      );
    }
  }

  my %seen;
  for my $option (@options) {
    croak "duplicate option id '" . $option->id . "' in choice '$data->{id}'" if $seen{ $option->id }++;
  }
  croak "choice '$data->{id}' offers fewer options than it asks to pick"
    if @options < ($data->{pick} // 1);

  return $class->new(
    id      => $data->{id},
    name    => $data->{name},
    pick    => $data->{pick} // 1,
    options => \@options,
  );
}

1;

__END__

=head1 SYNOPSIS

  my $choice = Game::OperationRebuild::Choice->from_hash({
    id => 'keen-senses', name => 'Keen Senses', pick => 1,
    options => [ { id => 'keen-perception', name => 'Perception',
                   channel => 'mutation',
                   effects => [ { kind => 'skill_proficiency', target => 'perception' } ] } ],
  });

=head1 DESCRIPTION

Some species traits ask the player to choose, for example an elf lineage or
a giant ancestry. A choice lists the options, which are ordinary
L<Game::OperationRebuild::Trait> objects, and how many to pick. The options a
creature selects become active traits (see L<Game::OperationRebuild::Creature>).

=attr id

Lower case identifier, unique within the species.

=attr name

Display name.

=attr pick

How many options must be selected, default 1.

=attr options

The traits on offer.

=method find_option

Returns the option with the given id, or nothing.

=method from_hash

Builds a choice from plain data. Dies on unknown keys, duplicate option ids,
or if there are fewer options than selections. C<options_from: skills>
generates a skill proficiency option for every skill.
