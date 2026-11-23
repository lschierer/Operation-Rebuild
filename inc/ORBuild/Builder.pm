package ORBuild::Builder;

# Module::Build subclass used only at build time (it lives in inc/, so it is
# never installed).
#
# Source files in lib/, bin/ and sbin/ keep their POD under __END__ and only
# contain the hand-written sections. When weaver.ini is present (a git
# checkout), POD is woven by Pod::Weaver without Dist::Zilla:
#
#   * into blib/ during ./Build, so lib/ in git stays unwoven;
#   * into the distribution directory during ./Build dist, so the tarball
#     ships finished POD and installing it needs no Pod::Weaver.
#
# The tarball omits weaver.ini (see MANIFEST.SKIP), which turns weaving off
# when somebody builds from the tarball.

use v5.42.0;
use utf8::all;
use parent 'Module::Build';

use File::Spec;
use Path::Tiny qw(path);

sub _weaving_enabled ($self) { -e 'weaver.ini' }

# Only load the heavy weaving modules when we actually weave.
sub _weaver ($self) {
  $self->{_or_weaver} //= do {
    require Pod::Weaver;
    require Pod::Elemental;
    require PPI::Document;
    require Software::License;
    Pod::Weaver->new_from_config({ root => '.' });
  };
}

sub _license_object ($self) {
  my $class = {
    open_source => 'ISC',    # see the comment on license in Build.PL
    perl        => 'Perl_5',
    mit         => 'MIT',
  }->{ $self->license } or return;
  my $full = "Software::License::$class";
  require "Software/License/$class.pm";
  my ($holder) = $self->dist_author->@*;
  $holder =~ s/\s*<[^>]*>\s*\z//;
  return $full->new({ holder => $holder, year => (localtime)[5] + 1900 });
}

# Rewrite one Perl file in place: collect its POD, run it through
# Pod::Weaver, and write code + __END__ + woven POD.
sub weave_file ($self, $file) {
  return unless $self->_weaving_enabled;

  $self->_weaver;    # loads PPI and friends
  my $source = path($file)->slurp_utf8;
  my $ppi    = PPI::Document->new(\$source)
    or die "Cannot parse $file with PPI: " . PPI::Document->errstr . "\n";

  my $pod_text = join "\n", map { $_->content } ($ppi->find('PPI::Token::Pod') || [])->@*;
  $ppi->prune('PPI::Token::Pod');
  $ppi->prune('PPI::Statement::End');
  $ppi->prune('PPI::Statement::Data');

  my $license = $self->_license_object;
  my $woven   = $self->_weaver->weave_document({
    pod_document => Pod::Elemental->read_string($pod_text),
    ppi_document => $ppi,
    filename     => $file,
    version      => $self->dist_version,
    authors      => [ $self->dist_author->@* ],
    ($license ? (license => $license) : ()),
  });

  my $code = $ppi->serialize;
  $code =~ s/\s+\z//;
  my $new = "$code\n\n__END__\n\n" . $woven->as_pod_string;

  my $path = path($file);
  my $mode = $path->stat->mode;    # spew replaces the file; keep the mode
  $path->remove;
  $path->spew_utf8($new);
  $path->chmod($mode & 07777);
  return 1;
}

sub process_pm_files ($self, $ext) {
  my $files = $self->find_pm_files;
  for my $file (sort keys %$files) {
    my $to = File::Spec->catfile($self->blib, $files->{$file});
    my $result = $self->copy_if_modified(from => $file, to => $to) or next;
    $self->weave_file($result);
  }
}

sub process_script_files ($self, @) {
  my $files = $self->find_script_files;
  return unless keys %$files;

  my $script_dir = File::Spec->catdir($self->blib, 'script');
  File::Path::mkpath($script_dir);

  for my $file (sort keys %$files) {
    my $result = $self->copy_if_modified($file, $script_dir, 'flatten') or next;
    $self->weave_file($result);
    $self->fix_shebang_line($result);
    $self->make_executable($result);
  }
}

sub ACTION_distdir ($self) {
  $self->SUPER::ACTION_distdir;
  return unless $self->_weaving_enabled;

  my $dir = $self->dist_dir;
  my @files;
  my $iter = path("$dir/lib")->iterator({ recurse => 1 });
  while (my $p = $iter->()) { push @files, $p if $p->is_file && $p =~ /\.pm\z/ }
  for my $script (sort keys %{ $self->script_files }) {
    push @files, path("$dir/$script") if -e "$dir/$script";
  }
  for my $p (@files) {
    $self->log_info("Weaving POD into $p\n");
    $self->weave_file("$p");
  }
}

1;
