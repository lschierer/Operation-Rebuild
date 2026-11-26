package Game::OperationRebuild::Data 0.001;

use v5.42.0;
use utf8::all;
use Mooish::Base;

# ABSTRACT: Load and validate game data files

use Carp qw(croak);
use File::Spec;
use YAML::PP;
use Game::OperationRebuild::Share;
use Game::OperationRebuild::Species;
use Game::OperationRebuild::Item;

# Identifiers become file names, so only allow plain slugs. This also keeps a
# caller from reaching outside the data directory with "../".
my $SLUG = qr/\A[a-z][a-z0-9-]*\z/;

has option share_dir => (isa => Str);

has field _yaml  => (lazy => 1, default => sub { YAML::PP->new });
has field _cache => (default => sub { {} });

sub root ($self) {
  return $self->has_share_dir ? $self->share_dir : Game::OperationRebuild::Share::share_dir();
}

sub _data_dir ($self, $kind) {
  return File::Spec->catdir($self->root, 'data', $kind);
}

sub _load_yaml ($self, $path) {
  croak "data file not found: $path" unless -f $path;
  my $data = eval { $self->_yaml->load_file($path) };
  croak "cannot parse $path: $@" if $@;
  croak "$path must contain a mapping" unless ref $data eq 'HASH';
  return $data;
}

sub species_ids ($self) {
  my $dir = $self->_data_dir('species');
  return () unless -d $dir;
  opendir(my $dh, $dir) or croak "cannot read $dir: $!";
  my @ids = sort map { /\A(.+)\.yaml\z/ ? $1 : () } readdir $dh;
  closedir $dh;
  return grep { /$SLUG/ } @ids;
}

sub species ($self, $id) {
  croak "invalid species id '$id'" unless defined $id && $id =~ $SLUG;
  return $self->_cache->{species}{$id} //= do {
    my $path = File::Spec->catfile($self->_data_dir('species'), "$id.yaml");
    my $data = $self->_load_yaml($path);
    croak "$path: id '" . ($data->{id} // '') . "' does not match file name '$id'"
      unless ($data->{id} // '') eq $id;
    my $species = eval { Game::OperationRebuild::Species->from_hash($data) };
    croak "invalid species data in $path: $@" if $@;
    $species;
  };
}

# All items, read once from every file in data/items. Each file is a mapping
# with an "items" list, so related items (weapons, tools, gear) can share a
# file. Item ids must be unique across all files.
sub _item_index ($self) {
  return $self->_cache->{items} //= do {
    my $dir = $self->_data_dir('items');
    my (%index, %source);
    if (-d $dir) {
      opendir(my $dh, $dir) or croak "cannot read $dir: $!";
      my @files = sort grep { /\A[a-z][a-z0-9-]*\.yaml\z/ } readdir $dh;
      closedir $dh;
      for my $file (@files) {
        my $path = File::Spec->catfile($dir, $file);
        my $data = $self->_load_yaml($path);
        my @extra = grep { $_ ne 'items' } keys %$data;
        croak "$path: unknown key(s) @extra" if @extra;
        croak "$path must have an 'items' list" unless ref $data->{items} eq 'ARRAY';
        for my $raw ($data->{items}->@*) {
          my $item = eval { Game::OperationRebuild::Item->from_hash($raw) };
          croak "invalid item in $path: $@" if $@;
          croak "duplicate item id '" . $item->id . "' in $path (also in $source{ $item->id })"
            if exists $index{ $item->id };
          $index{ $item->id }  = $item;
          $source{ $item->id } = $path;
        }
      }
    }
    \%index;
  };
}

sub item_ids ($self) { return sort keys $self->_item_index->%* }

sub item ($self, $id) {
  croak "invalid item id '" . ($id // '') . "'" unless defined $id && $id =~ $SLUG;
  return $self->_item_index->{$id} // croak "item not found: $id";
}

sub items_in_group ($self, $group) {
  return grep { $_->has_group && $_->group eq $group } map { $self->_item_index->{$_} } $self->item_ids;
}

1;

__END__

=head1 SYNOPSIS

  my $data    = Game::OperationRebuild::Data->new;
  my $dwarf   = $data->species('dwarf');
  my @species = map { $data->species($_) } $data->species_ids;

=head1 DESCRIPTION

Loads YAML rule data from F<share/data/> and turns it into validated objects.
Each kind of data has its own directory: species (one file per species) and
items (one file per category, each holding a list of items). Files are
parsed with L<YAML::PP>, which does not construct arbitrary Perl objects, and
every file is checked when loaded, so a typo in a data file fails at load
time with the file name in the message. Loaded objects are cached.

=attr share_dir

Optional data root, mainly for tests. By default
L<Game::OperationRebuild::Share> finds it.

=method root

The data root in use.

=method species_ids

Sorted ids of the species files present.

=method item_ids

Sorted ids of every item defined in F<data/items>.

=method item

C<< $data->item('dagger') >> returns a L<Game::OperationRebuild::Item>. Dies if
the id is not a plain identifier or no such item exists. All item files are
validated the first time any item is requested, and a duplicate id in two files
is an error.

=method items_in_group

All items whose C<group> matches, for example C<gaming-set>.

=method species

C<< $data->species('dwarf') >> returns a L<Game::OperationRebuild::Species>.
Dies if the id is not a plain identifier, the file is missing or malformed, or
the data is invalid.
