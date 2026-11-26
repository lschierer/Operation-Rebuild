package Game::OperationRebuild::Currency 0.001;

use v5.42.0;
use utf8::all;

# ABSTRACT: Coins, stored as whole copper pieces

use Carp qw(croak);

# Value of each coin in copper pieces (SRD 5.2.1, "Coins").
our %VALUE = (CP => 1, SP => 10, EP => 50, GP => 100, PP => 1000);

# "25 GP", "5 sp", "1,000 GP" or "2.5 GP" to a whole number of copper pieces.
sub parse ($class, $text) {
  croak "cost is required" unless defined $text;
  $text =~ /\A\s*(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d+))?\s*([A-Za-z]{2})\s*\z/
    or croak "cannot parse cost '$text'";
  my ($whole, $fraction, $coin) = ($1, $2 // '', uc $3);
  $whole =~ s/,//g;
  my $value = $VALUE{$coin} // croak "unknown coin '$coin' in '$text'";
  # Work in integers: "2.5 GP" is 25/10 of 100 copper.
  my $scale = 10**length $fraction;
  my $copper = ($whole . $fraction) * $value;
  croak "cost '$text' is not a whole number of copper pieces" if $copper % $scale;
  return $copper / $scale;
}

# Whole copper pieces to the largest of GP, SP, CP that divides them exactly.
sub format ($class, $copper) {
  croak "copper must be a non-negative integer" unless defined $copper && $copper =~ /\A\d+\z/;
  for my $coin (qw(GP SP)) {
    return sprintf('%s %s', _commas($copper / $VALUE{$coin}), $coin)
      if $copper >= $VALUE{$coin} && $copper % $VALUE{$coin} == 0;
  }
  return "$copper CP";
}

sub _commas ($number) {
  1 while $number =~ s/^(\d+)(\d{3})/$1,$2/;
  return $number;
}

1;

__END__

=head1 SYNOPSIS

  my $copper = Game::OperationRebuild::Currency->parse('25 GP');   # 2500
  say Game::OperationRebuild::Currency->format(50);                # 5 SP

=head1 DESCRIPTION

Prices and wealth are kept as whole copper pieces so that arithmetic is exact.
One silver is 10 copper, one electrum 50, one gold 100 and one platinum 1000.

=head1 METHODS

=head2 parse

C<< ->parse('5 SP') >> returns copper pieces. Accepts commas (C<1,000 GP>) and
decimals (C<2.5 GP>) as long as the result is a whole number of copper. Dies on
anything else.

=head2 format

C<< ->format(2500) >> returns C<25 GP>, using gold or silver when the amount
divides evenly and copper otherwise.
