package Game::OperationRebuild::Effect 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: One atomic change a trait makes to a creature

use Carp qw(croak);
use Game::OperationRebuild::Rules qw(:all);

use constant KINDS => qw(
  ability_score skill_proficiency save_proficiency speed sense
  resistance hit_points_per_level advantage disadvantage
);

use constant MODES => qw(add set);

has param kind  => (isa => Enum [KINDS]);
has param target => (isa => Str);
has param value  => (isa => Int, default => 1);
has param mode   => (isa => Enum [MODES], default => 'add');

# The legal targets depend on the kind. Free-form tags are used for
# advantage and disadvantage so rules can match them later.
my %VALID_TARGET = (
  ability_score       => sub ($t) { is_ability($t) },
  skill_proficiency   => sub ($t) { is_skill($t) },
  save_proficiency    => sub ($t) { is_ability($t) },
  speed               => sub ($t) { scalar grep { $_ eq $t } @MOVEMENT_MODES },
  sense               => sub ($t) { scalar grep { $_ eq $t } @SENSES },
  resistance          => sub ($t) { scalar grep { $_ eq $t } @DAMAGE_TYPES },
  hit_points_per_level => sub ($t) { $t eq 'max' },
  advantage           => sub ($t) { $t =~ /\A[a-z][a-z0-9:_ -]*\z/ },
  disadvantage        => sub ($t) { $t =~ /\A[a-z][a-z0-9:_ -]*\z/ },
);

sub BUILD ($self, $args) {
  my $kind = $self->kind;
  croak sprintf("invalid target '%s' for effect kind '%s'", $self->target, $kind)
    unless $VALID_TARGET{$kind}->($self->target);
  croak "sense and speed effects need a positive value"
    if ($kind eq 'sense' || ($kind eq 'speed' && $self->mode eq 'set')) && $self->value < 1;
  return;
}

1;

__END__

=head1 SYNOPSIS

  my $effect = Game::OperationRebuild::Effect->new(
    kind   => 'sense',
    target => 'darkvision',
    value  => 120,
  );

=head1 DESCRIPTION

An effect is the smallest unit of change in the rules. Species traits, class
features, backgrounds, age stages, equipment and technology all work by
carrying effects, so they combine in one way. Effects are validated when they
are built, which catches typos in data files early.

=head2 Kinds

=over 4

=item C<ability_score>

Target is an ability name. C<add> adds C<value>; C<set> makes the score at
least C<value>.

=item C<skill_proficiency>, C<save_proficiency>

Target is a skill or ability name.

=item C<speed>

Target is a movement mode. C<add> adds feet; C<set> makes the speed at least
C<value>.

=item C<sense>

Target is a sense name and C<value> is its range in feet. The largest range
wins.

=item C<resistance>

Target is a damage type.

=item C<hit_points_per_level>

Target is C<max>. C<value> hit points are added for each level.

=item C<advantage>, C<disadvantage>

Target is a free-form tag such as C<save:poisoned>.

=back

=attr kind

One of the kinds above.

=attr target

What the effect applies to; the legal values depend on the kind.

=attr value

Integer amount, default 1.

=attr mode

C<add> (default) or C<set>.
