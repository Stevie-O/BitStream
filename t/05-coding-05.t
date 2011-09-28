#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib BitStream/t/lib Data/BitStream/t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {
  subtest "$encoding" => sub { test_encoding($encoding); };
}
done_testing();


sub test_encoding {
  my $encoding = shift;

  plan tests => scalar @implementations;

  foreach my $type (@implementations) {
    my $stream = new_stream($type);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my ($esub, $dsub, $param) = sub_for_string($encoding);
    BAIL_OUT("No sub for encoding $encoding") unless defined $esub and defined $dsub;
    my $success = 1;
    foreach my $n (0 .. 129) {
      $stream->erase_for_write;
      $esub->($stream, $param, $n);
      $stream->rewind_for_read;
      my $v = $dsub->($stream, $param);
      $success = 0 if $v != $n;
    }
    ok($success, "$encoding put/get from 0 to 129");
  }
}