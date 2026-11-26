package Game::OperationRebuild::Item 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: A piece of equipment

use Carp qw(croak);
use Game::OperationRebuild::Currency;
use Game::OperationRebuild::Dice;
use Game::OperationRebuild::Rules qw(@ABILITIES @DAMAGE_TYPES is_ability);

use constant CATEGORIES => qw(weapon armor tool gear ammunition);

# SRD 5.2.1 weapon vocabulary.
use constant WEAPON_PROPERTIES => qw(
  ammunition finesse heavy light loading reach thrown two-handed versatile
);
use constant MASTERIES => qw(cleave graze nick push sap slow topple vex);

my @KNOWN_KEYS = qw(
  id name category cost weight group bundle uses description weapon tool
);
my @WEAPON_KEYS = qw(
  category kind damage damage_type properties range versatile ammunition mastery
);
my @TOOL_KEYS = qw(ability utilize craft);

has param id       => (isa => StrMatch [qr/\A[a-z][a-z0-9-]*\z/]);
has param name     => (isa => NonEmptySimpleStr);
has param category => (isa => Enum [CATEGORIES]);

# Price in copper pieces. Data files write it as text such as "25 GP".
has param cost   => (isa => PositiveOrZeroInt, default => 0);
has param weight => (isa => PositiveOrZeroNum, default => 0);    # pounds

# Items of a kind a choice can pick from (for example "gaming-set").
has option group => (isa => StrMatch [qr/\A[a-z][a-z0-9-]*\z/]);

# How many individual pieces one purchase contains (20 arrows).
has option bundle => (isa => PositiveInt);

# Charges a single item holds (a Healer's Kit has ten uses).
has option uses        => (isa => PositiveInt);
has option description => (isa => Str);

has option weapon => (isa => HashRef);
has option tool   => (isa => HashRef);

sub BUILD ($self, $args) {
  croak "item '" . $self->id . "' needs a weapon section" if $self->category eq 'weapon' && !$self->has_weapon;
  croak "item '" . $self->id . "' has a weapon section but is not a weapon" if $self->has_weapon && $self->category ne 'weapon';
  croak "item '" . $self->id . "' needs a tool section" if $self->category eq 'tool' && !$self->has_tool;
  croak "item '" . $self->id . "' has a tool section but is not a tool" if $self->has_tool && $self->category ne 'tool';
  $self->_check_weapon if $self->has_weapon;
  $self->_check_tool   if $self->has_tool;
  return;
}

sub _unknown_keys ($self, $section, $data, @allowed) {
  my %ok  = map { $_ => 1 } @allowed;
  my @bad = grep { !$ok{$_} } sort keys %$data;
  croak "unknown key(s) in $section of item '" . $self->id . "': @bad" if @bad;
}

sub _check_weapon ($self) {
  my $w  = $self->weapon;
  my $id = $self->id;
  $self->_unknown_keys(weapon => $w, @WEAPON_KEYS);
  croak "weapon '$id': category must be simple or martial" unless ($w->{category} // '') =~ /\A(?:simple|martial)\z/;
  croak "weapon '$id': kind must be melee or ranged"       unless ($w->{kind} // '') =~ /\A(?:melee|ranged)\z/;
  croak "weapon '$id': damage_type '" . ($w->{damage_type} // '') . "' is not a damage type"
    unless grep { $_ eq ($w->{damage_type} // '') } @DAMAGE_TYPES;
  for my $field (qw(damage versatile)) {
    next unless defined $w->{$field};
    my $dice = eval { Game::OperationRebuild::Dice->parse($w->{$field}) };
    croak "weapon '$id': $field '$w->{$field}' is not a dice expression" unless $dice;
  }
  croak "weapon '$id': damage is required" unless defined $w->{damage};
  my @properties = ($w->{properties} // [])->@*;
  for my $property (@properties) {
    croak "weapon '$id': unknown property '$property'" unless grep { $_ eq $property } WEAPON_PROPERTIES;
  }
  croak "weapon '$id': versatile damage needs the versatile property"
    if defined $w->{versatile} && !grep { $_ eq 'versatile' } @properties;
  croak "weapon '$id': the versatile property needs versatile damage"
    if !defined $w->{versatile} && grep { $_ eq 'versatile' } @properties;
  croak "weapon '$id': thrown or ammunition weapons need a range"
    if !defined $w->{range} && grep { $_ eq 'thrown' || $_ eq 'ammunition' } @properties;
  if (defined $w->{range}) {
    croak "weapon '$id': range needs positive normal and long distances"
      unless ref $w->{range} eq 'HASH' && ($w->{range}{normal} // 0) > 0 && ($w->{range}{long} // 0) >= $w->{range}{normal};
  }
  croak "weapon '$id': ammunition property needs an ammunition type"
    if grep({ $_ eq 'ammunition' } @properties) && !defined $w->{ammunition};
  croak "weapon '$id': mastery '" . ($w->{mastery} // '') . "' is not a known mastery"
    unless grep { $_ eq ($w->{mastery} // '') } MASTERIES;
  return;
}

sub _check_tool ($self) {
  my $t = $self->tool;
  $self->_unknown_keys(tool => $t, @TOOL_KEYS);
  croak "tool '" . $self->id . "': ability '" . ($t->{ability} // '') . "' is not an ability"
    unless is_ability($t->{ability});
  return;
}

sub from_hash ($class, $data) {
  croak "item data must be a hash" unless ref $data eq 'HASH';
  my %known = map { $_ => 1 } @KNOWN_KEYS;
  my @bad   = grep { !$known{$_} } sort keys %$data;
  croak "unknown key(s) in item '" . ($data->{id} // '?') . "': @bad" if @bad;

  my %args = %$data;
  $args{cost} = Game::OperationRebuild::Currency->parse($data->{cost}) if defined $data->{cost};
  return $class->new(%args);
}

sub cost_text ($self) { Game::OperationRebuild::Currency->format($self->cost) }

1;

__END__

=head1 SYNOPSIS

  my $dagger = Game::OperationRebuild::Item->from_hash({
    id => 'dagger', name => 'Dagger', category => 'weapon',
    cost => '2 GP', weight => 1,
    weapon => { category => 'simple', kind => 'melee', damage => '1d4',
                damage_type => 'piercing', properties => [qw(finesse light thrown)],
                range => { normal => 20, long => 60 }, mastery => 'nick' },
  });
  say $dagger->cost_text;    # 2 GP

=head1 DESCRIPTION

Equipment in the SRD sense: weapons, tools, adventuring gear and ammunition.
Armor is allowed as a category but has no data model yet. Prices are stored as
copper pieces (see L<Game::OperationRebuild::Currency>), weights in pounds.

Weapons and tools carry a section with the stats the rules need. Both are
checked when the item is built, so a mistyped damage type or mastery fails
when the data loads.

=attr id

Lower case identifier with digits and hyphens.

=attr name

Display name.

=attr category

C<weapon>, C<armor>, C<tool>, C<gear> or C<ammunition>.

=attr cost

Price in copper pieces. C<from_hash> accepts text such as C<25 GP>.

=attr weight

Weight in pounds, default 0.

=attr group

Optional group name, for choices that pick one of a kind (for example
C<gaming-set>).

=attr bundle

Optional: how many pieces one purchase holds (20 arrows).

=attr uses

Optional: charges the item holds.

=attr description

Optional rules text.

=attr weapon

Weapon stats: C<category> (simple or martial), C<kind> (melee or ranged),
C<damage>, C<damage_type>, optional C<properties>, C<versatile> damage,
C<range> (C<normal> and C<long> feet), C<ammunition> type, and C<mastery>.

=attr tool

Tool stats: C<ability> and optional C<utilize> and C<craft> lists.

=method from_hash

Builds an item from plain data. Dies on unknown keys or invalid values.

=method cost_text

The price as text, for example C<25 GP>.
