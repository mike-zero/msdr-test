#!/usr/bin/perl -w

use strict;
use integer;

my $filename = shift || '-';

my $bufsize = 2 * 16384;
my $buf = 0 x $bufsize;

my $ast_lim = 80;

my @amp_cache;

sub SCALE_BITS() { 8 }
sub AVG_FACTOR_BITS { 3 }

# states
sub STATE_FLAT() { 1 }
sub STATE_RISE() { 2 }
sub STATE_FALL() { 3 }

my ($i, $q);
my ($amp, $delta, $abs_delta, $prev_delta, $prev_amp, $prev_abs_delta) = (0, 0, 0, 0, 0, 0);
my ($avg_sum, $avg_delta) = (0, 1 << (SCALE_BITS+2));
my ($state, $prev_state) = (STATE_FLAT, STATE_FLAT);	# flat, up, down (high, low, rise, fall?)

sub calc_amp($$) {
	my ($i,$q) = @_;
	$amp_cache[$i][$q] = int(sqrt(($i*$i+$q*$q) << (SCALE_BITS * 2)));
	return $amp_cache[$i][$q];
}

sub set_state($) {
	$prev_state = $state;
	$state = shift || return;
	print "STATE $prev_state -> $state\n";
}

warn "Start: ".(scalar localtime(time));

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	foreach my $s (0..(length($buf)/2-1)) {
		$i = ord(substr($buf, $s*2, 1));
		$q = ord(substr($buf, $s*2 + 1, 1));
		# print "$i\t$q\t";
		$i = $i & 0x80 ? $i & 0x7F : $i ^ 0x7F;
		$q = $q & 0x80 ? $q & 0x7F : $q ^ 0x7F;
		$amp = $amp_cache[$i][$q];
		$amp = calc_amp($i, $q) unless defined $amp;

		# $delta = $amp - $avg_sum/$avg_factor;

		if ($state == STATE_FLAT) {
			$delta = $amp - ($avg_sum >> AVG_FACTOR_BITS); # $prev_amp;
			$abs_delta = abs($delta);
			if ($abs_delta >> (SCALE_BITS+1) and $abs_delta > $prev_abs_delta and $abs_delta > $avg_delta >> (AVG_FACTOR_BITS-1)) {
				set_state($delta > 0 ? STATE_RISE : STATE_FALL);
			} else {
				$avg_sum += $delta; # $amp - ($avg_sum >> AVG_FACTOR_BITS);
				$avg_delta += $abs_delta - ($avg_delta >> AVG_FACTOR_BITS);
			}
		} elsif ($state == STATE_RISE or $state == STATE_FALL) {
			$delta = $amp - $prev_amp;
			$abs_delta = abs($delta);
			if ($abs_delta < $prev_abs_delta>>1 or $delta>0 and $prev_delta<0 or $delta<0 and $prev_delta>0) {
				set_state(STATE_FLAT);
				$avg_sum = $amp << AVG_FACTOR_BITS;
				$avg_delta = $abs_delta << AVG_FACTOR_BITS;
			}
		}


		my $amp_ast = $amp>>SCALE_BITS <= $ast_lim ? $amp>>SCALE_BITS : $ast_lim;
		printf "%3d %3d amp=%6u avg=%6u d=%5d avgd=%5d %-${ast_lim}s\n", $i, $q, $amp, $avg_sum >> AVG_FACTOR_BITS, $delta, $avg_delta >> AVG_FACTOR_BITS, '*' x $amp_ast;
		$prev_amp = $amp;
		$prev_delta = $delta;
		$prev_abs_delta = $abs_delta;
	}
}
close F;

warn "Stop:  ".(scalar localtime(time));
