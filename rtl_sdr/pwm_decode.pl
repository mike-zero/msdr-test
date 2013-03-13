#!/usr/bin/perl -w

use strict;
use integer;

my $filename = shift || '-';

my $bufsize = 2 * 16384;
my $buf = 0 x $bufsize;

my $ast_lim = 80;

my @amp_cache;

my ($i, $q);
my ($amp, $dev, $old_dev, $old_amp) = (0, 0, 0, 0);
my ($avg_sum, $avg_dev, $avg_factor) = (0, 0x3FF, 8);
my $state = 'flat';	# flat, up, down (high, low?)

sub calc_amp($$) {
	my ($i,$q) = @_;
	$amp_cache[$i][$q] = int(sqrt(($i*$i+$q*$q)<<16));
	return $amp_cache[$i][$q];
}

warn "Start: ".(scalar localtime(time));

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	foreach my $s (0..(length($buf)/2-1)) {
		$i = ord(substr($buf, $s*2, 1));
		$q = ord(substr($buf, $s*2 + 1, 1));
#print "$i\t$q\t";
		$i = $i & 0x80 ? $i & 0x7F : $i ^ 0x7F;
		$q = $q & 0x80 ? $q & 0x7F : $q ^ 0x7F;

		$amp = $amp_cache[$i][$q];
		$amp = calc_amp($i, $q) unless defined $amp;

		# $dev = $amp - $avg_sum/$avg_factor;
		$dev = $amp - $old_amp;

		# if (abs($dev) > 2 * $avg_dev/$avg_factor) {
		if ($dev * $old_dev >= 0 and abs($dev) < abs($old_dev)) {
			print "!!!!\n";
			$avg_sum = $amp * $avg_factor;
			# $avg_dev = 2 * $avg_dev; # = abs($dev) * $avg_factor;
			$avg_dev = 0;
		} else {
			$avg_sum = $avg_sum * ($avg_factor - 1) / $avg_factor + $amp;
			$avg_dev = $avg_dev * ($avg_factor - 1) / $avg_factor + abs($dev);
		}

		my $amp_ast = $amp>>8 <= $ast_lim ? $amp>>8 : $ast_lim;
		my $avg_ast = ($avg_sum/$avg_factor)>>8 <= $ast_lim ? ($avg_sum/$avg_factor)>>8 : $ast_lim;
		printf "%3d %3d amp=%6u d=%5d d_avg=%6u %-${ast_lim}s avg=%5u %-${ast_lim}s\n", $i, $q, $amp, $dev, $avg_dev/$avg_factor, '*' x $amp_ast, $avg_sum/$avg_factor, '*' x $avg_ast;
		$old_amp = $amp;
		$old_dev = $dev;
	}
}
close F;

warn "Stop:  ".(scalar localtime(time));
