#!/usr/bin/perl
use strict;
use warnings;

sub die_usage { die "Usage: -encode|-decode unary|gamma|delta|omega|fib\n"; }

use Getopt::Long;
my $emethod;
my $dmethod;
GetOptions('help|usage|?' => sub { die_usage() },
           'encode=s' => \$emethod,
           'decode=s' => \$dmethod);
die_usage if (defined $emethod and defined $dmethod);
my $sub;
if (defined $emethod) {
  if    ($emethod eq 'unary') { $sub = sub { encode_unary(shift) }; }
  elsif ($emethod eq 'gamma') { $sub = sub { encode_gamma(shift) }; }
  elsif ($emethod eq 'delta') { $sub = sub { encode_delta(shift) }; }
  elsif ($emethod eq 'omega') { $sub = sub { encode_omega(shift) }; }
  elsif ($emethod eq 'fib'  ) { $sub = sub { encode_fib(shift) }; }
  else                        { die "Unknown code: $emethod\n"; }
} elsif (defined $dmethod) {
  if    ($dmethod eq 'unary') { $sub = sub { decode_unary(shift) }; }
  elsif ($dmethod eq 'gamma') { $sub = sub { decode_gamma(shift) }; }
  elsif ($dmethod eq 'delta') { $sub = sub { decode_delta(shift) }; }
  elsif ($dmethod eq 'omega') { $sub = sub { decode_omega(shift) }; }
  elsif ($dmethod eq 'fib'  ) { $sub = sub { decode_fib(shift) }; }
  else                        { die "Unknown code: $dmethod\n"; }
}
die_usage unless defined $sub;


while (<STDIN>) {
  chomp;
  die "Must have a binary string for decoding"
      if (defined $dmethod) && (length($_) == 0 or $_ =~ /[^01]/);
  print $sub->($_), "\n";
}



# Helper functions
# convert to/from decimal and BE binary, should work with 32- and 64-bit.
sub dec_to_bin {
  my $v =  ($_[0] > 32)  ?  pack("Q", $_[1])  :  pack("L", $_[1]);
  scalar reverse unpack("b$_[0]", $v);
}
sub bin_to_dec { no warnings 'portable'; oct '0b' . substr($_[1], 0, $_[0]); }
sub base_of { my $d = shift; my $base = 0; $base++ while ($d >>= 1); $base; }


# Unary:  0 based
sub encode_unary {
  ('0' x (shift)) . '1';
}
sub decode_unary {
  index($_[0], '1', 0);
}


# Gamma:  1 based
sub encode_gamma {
  my $d = shift;
  die "Value must be between 1 and ~0" unless $d >= 1 and $d <= ~0;
  my $base = base_of($d);
  my $str = encode_unary($base);
  $str .= dec_to_bin($base, $d)  if $base > 0;
  $str;
}
sub decode_gamma {
  my $str = shift;
  my $base = decode_unary($str);
  my $val = 1 << $base;
  $val |= bin_to_dec($base, substr($str, $base+1))  if $base > 0;
  $val;
}


# Delta:  1 based
sub encode_delta {
  my $d = shift;
  die "Value must be between 1 and ~0" unless $d >= 1 and $d <= ~0;
  my $base = base_of($d);
  my $str = encode_gamma($base+1);
  $str .= dec_to_bin($base, $d)  if $base > 0;
  $str;
}
sub decode_delta {
  my $str = shift;
  my $base = decode_gamma($str) - 1;
  my $val = 1 << $base;
  if ($base > 0) {
    # We have to figure out how far we need to look
    my $shift = length(encode_gamma($base+1));
    $val |= bin_to_dec($base, substr($str, $shift));
  }
  $val;
}


# Omega:  1 based
sub encode_omega {
  my $d = shift;
  die "Value must be between 1 and ~0" unless $d >= 1 and $d <= ~0;

  my $str = '0';
  while ($d > 1) {
    my $base = base_of($d);
    $str = dec_to_bin($base+1, $d) . $str;
    $d = $base;
  }
  $str;
}

sub decode_omega {
  my $str = shift;
  my $val = 1;
  while (substr($str,0,1) eq '1') {
    my $bits = $val+1;
    die "off end of string" unless length($str) >= $bits;
    $val = bin_to_dec($bits, $str);
    substr($str,0,$bits) = '';
  }
  $val;
}


# Fibonacci:  1 based
# Specifically, the C1 (m=2) code of Fraenkel and Klein, 1996.
my @fibs;    # Holds F[2] ... -> (1, 2, 3, 5, 8, ...)
sub _calc_fibs {
  @fibs = ();
  my ($v2, $v1) = (0,1);
  while ($v1 <= ~0) {
    ($v2, $v1) = ($v1, $v2+$v1);
    push(@fibs, $v1);
  }
}
sub encode_fib {
  my $d = shift;
  die "Value must be between 1 and ~0" unless $d >= 1 and $d <= ~0;
  _calc_fibs unless defined $fibs[0];
  # Find the largest F(s) bigger than $n
  my $s =  ($d < $fibs[30])  ?  0  :  ($d < $fibs[60])  ?  31  :  61;
  $s++ while ($d >= $fibs[$s]);
  my $r = '1';
  while ($s-- > 0) {
    if ($d >= $fibs[$s]) {
      $d -= $fibs[$s];
      $r .= "1";
    } else {
      $r .= "0";
    }
  }
  scalar reverse $r;
}
sub decode_fib {
  my $str = shift;
  die "Invalid Fibonacci code" unless $str =~ /^[01]*11$/;
  _calc_fibs unless defined $fibs[0];
  my $val = 0;
  foreach my $b (0 .. length($str)-2) {
    $val += $fibs[$b]  if substr($str, $b, 1) eq '1';
  }
  $val;
}

__END__

=pod

=head1 NAME

integercoding.pl - simple encoding and decoding using integer codings

=head1 DESCRIPTION

Example code to encode and decode numbers into binary strings using various
integer codings.

=head1 SYNOPSIS

Command line examples:

  echo "15" | perl integercoding.pl -encode omega
  echo "00010001110111" | perl integercoding.pl -decode delta


Subroutine examples:

  print "$_ encoded in gamma is ", encode_gamma($_), "\n"  for (1 .. 10);

  my $delta_str = encode_delta(317);
  my $fib_str = encode_fib( decode_delta( $delta_str ) );
  print "fib str: $fib_str encodes ", decode_fib($fib_str), "\n";


Print out a table of code sizes:

  printf("%7s   %7s  %7s  %7s  %7s  %7s  %7s\n",
         "Value", "Unary", "Binary", "Gamma", "Delta", "Omega", "Fib");
  my @vals = (1..5);
  push @vals, $vals[-1]*2, $vals[-1]*4, $vals[-1]*10  for (1..5);
  foreach my $n (@vals) {
    printf("%7d   %7s  %7s  %7s  %7s  %7s  %7s\n",
           $n, $n+1, base_of($n)+1,
           length(encode_gamma($n)), length(encode_delta($n)),
           length(encode_omega($n)), length(encode_fib($n))     );
  }

=head1 FUNCTIONS

The C<encode_> methods take a single unsigned integer as input and produce a
string of 0 and 1 characters representing the bit encoding of the integer
using that code.

  $str = encode_unary(8);    # die unless $str eq '000000001';
  $str = encode_gamma(8);    # die unless $str eq '0001000';
  $str = encode_delta(8);    # die unless $str eq '00100000';
  $str = encode_omega(8);    # die unless $str eq '1110000';
  $str = encode_fib(8);      # die unless $str eq '000011';

The C<decode_> methods take a single binary string as input and produce an
unsigned integer output decoded from the bit encoding.

  $n = decode_unary('000000000000001');  die unless $n == 14;
  $n = decode_gamma('0001110');          die unless $n == 14;
  $n = decode_delta('00100110');         die unless $n == 14;
  $n = decode_omega('1111100');          die unless $n == 14;
  $n = decode_fib(  '1000011');          die unless $n == 14;

=head1 SEE ALSO

The CPAN module L<Data::BitStream> includes these codes and more.

Peter Elias, "Universal Codeword Sets and Representations of the Integers", IEEE Trans. Information Theory, Vol 21, No 2, pp 194-203, Mar 1975.

Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers," Technical Report 137, Department of Computer Science, The University of Auckland, Auckland, New Zealand, December 1996.

=over 4

=item L<http://en.wikipedia.org/wiki/Unary_coding>

=item L<http://en.wikipedia.org/wiki/Elias_gamma_coding>

=item L<http://en.wikipedia.org/wiki/Elias_delta_coding>

=item L<http://en.wikipedia.org/wiki/Elias_omega_coding>

=item L<http://en.wikipedia.org/wiki/Fibonacci_coding>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
