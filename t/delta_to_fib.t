#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);
use lib qw(t/lib BitStream/t/lib Data/BitStream/t/lib);
use BitStreamTest;

# Inspired by http://golf.shinh.org/p.rb?Elias+delta+to+Fibonacci
# though without golfing (my program is about 175 characters when
# compacted given the relatively long package and method names).
# None of the Perl implementations on that site work on my machine,
# though this code works fine.

my @in = qw(
000110111001011110000011110011100001000000011001001011011100011111100111100010000001010110101001101111010010
000110101011101001100001011010010110011010100100100010101010111010000101000001100000001000101000010000011110101110110
00011110100101101100000001000110100000000111000000100010011001110001110000101110011001000001101110100101001
0000100111010100100001101010000100010101101110000111000100110110010000010010010010011100011000000101000011000110110111101
00001000101000111110000000000100001010100101101000001111000101111101100000100011111111011011101
0000101000011100101011101001000111110110000010001000010001001010000010110000011101100110000010
000010000101110110010001000010011011110111010011110000111000011000101100000100010010001100001101
000010001011101010011011000001000110110101000100000000101000110101100110110010000010011111001101111101101
00001000100000101010110010000100111100110011001110010000100011100010010010111000100110100000
0000101111011110001010100100001000111010100000111110000100010100101011010100000110000001011101000010000001111100001000
000010000110000011001001000100000001110000100111101101001101101110001101001001100101
0000100000100101100001010000100101110110000101100100001000100000110011101100001111010011001101110000100010110110100011010
0001111001000100001010001011001100101000001000101001001110010010000100111110111100110011110000101001110001001001101110
00011010010000101000000100000110100100111000000101001101000111101111111000110011010100010
000010001100100101100001000001000001100100000111100001000011011000110011100011100111100100100
00011101111100110001000010000001010010101001000110111011111101100001001010111010010101110
000101111111001110000100100111000111001001000010111011010001000111010011011011110001101111000111110
00011111011011011111000011100000011111010000010011111001100011110011000010011100101110010010110000110000001111111
00001001111010010001111010000001001010100111110111001000010001100010000010100000001001010100111101101011
00001000000000011110110100001000101011111000100010001110101110100001100001001000101110000000000
000111010111111100000001111110101101000110001111100001010000100001110101100000000000001001000010011101111100
000111100100000000011000010011000101011101110000000010001110100100000101000011101000111111101
000010100100111001001110100100001010001101000101010100000001110001110101100100001001101010011010100111100001001000110001001011010
000010000000010011110100000111111001111110011000111111111001010001000111110110111011011
0000101110111011011011000110011000010011011011101011010111000010000010011010001001000010011011111011111000110
0001101011100110101000101111100001010000100111011010111100111110001111010110111010100000100011111000101001000
000010010001100100110110000000100110100010110100111110000100101000011110001001000011100000110000101000110011111101000
0001111110001000010110000101001011101010100110010000010001010000100111011100011100100001101011
0001101010010000000000010010000011111010001010001111100111011110100000101000000111011010011011
0001101001001010011000111101011011011010000110010011011010000010000110001010100101
);

my @out = qw(
010001001010100000110010100010000101000011100100001000010011000001010101010000000111001010000101000010000010010011
00001001000010100110101000010100010000000000010101100010100000101100000101010100010001001000011001001000010100100000011
0100010010010100100011101000100001000010000101101000101010000101000000110001000100000001110000000010001000011
01001010101000001001010100111000000100001000100100011010000001000110101000001000010000000101110000100100010100010010100011
1010010101001001001000011010010000101001000100011000000001010000000001100010001000000001010000011
0000010101010001010000001001100001010101010001010110101000100100100000000011100100001010001010011
101001000000001010100011100000100100000000101010001101001000000001010011000100000100001010101011
01000010101000001000100111000001010001010001001011101001010101000001000100010111010101000101001000100101011
1000100000010000100010111000000010001010100001001011010001000001001000010101100010001000011
100100010100101001000100010001001110101001001001010001110001010100100001010000110100001000101001110101010010000100001011
0010101010100000000100111010100101101001000000100000000001010110101000000101000011
0000100100100000100101101000000000101010010001001110010000001010001000101100000010000000101000110100101001000100000010011
0010100000010100000011100100000001001110100101000000001010000110000000000010010100010101011000000010100101001000100100011
010001001000100001110101000000101010101011000101010010010000000000100011010010100010001011
000000010000001010101001100100000101000010101011001010000000010010010011101010010100001000011
0000100010000010010111010010100000000101001110101000100101000011000100010000101000000100011
01000101000010011010101010001001010001010111010000000100001110000100000001010001100101001010101000011
0000010100000010101011101000101000000100111010001000001010000100101011101001001010100101001001001101000000101010011
10010100101000001010010010110010010010010000100010000111000010100010100001010011100100101010000010001000011
10101001000010000100011100010000101001010010001101010000000001001001100100100000010000100010011
01000001001001001001100010000010010100000011001010010000100000101110010000100100001001100000100010010010000100011
10100010010001000000110000001000101001000100010110100101001001000010101011000000100001000100011
0001010010001001000100000000111000000001010100101010000101110100010010001001011001001000000001000000100001100101001000010010100010011
1010100010100010010001100010001000000100000011010101000100001010000110000001010000010101011
01001000000010010101010100100000111000100000001000000100100011100001001000100010010110100010000010101001010100011
1001010000100001011100100000101000111001000000010101001000001011010000010101000001001101001001010000010100000011
00010100100000000010010011101010000010100001010000001100101000010010101000000001101010100101000010011100000010100101011
01000101000100000000011010000000100001010101010000011010100000010010000100001100101000000000101011
101000101000001001101010010010101010101000011100100010000100100101101001000101001000001010000011
01001001010010000110101010001010000010011010100000100010011000010000100010000010011
);

my $nstrings = scalar @in;
die unless scalar @out == $nstrings;

my @implementations = impl_list;

plan tests => scalar @implementations * $nstrings;

foreach my $type (@implementations) {
  my $dstream = new_stream($type);
  my $fstream = new_stream($type);
  foreach my $n (1 .. scalar @in) {
    $dstream->from_string($in[$n-1]);
    $fstream->erase_for_write;

    # Single value at a time:
    #  while (defined (my $val = $dstream->get_delta())) {
    #    $fstream->put_fib($val);
    #  }

    # get / put entire stream:
    $fstream->put_fib( $dstream->get_delta(-1) );

    my $fstr = $fstream->to_string();
    ok($fstr eq $out[$n-1], "$type string $n");
  }
}
done_testing();
