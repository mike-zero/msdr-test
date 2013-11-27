#!/usr/bin/perl -w

use strict;

my $state = 0;
#my @buf;
#my $buf_pos = 0;

my $T = 0;
my @packet = ();
my $byte = 0;
my $bit_pos = 4;

sub getnext() {
	my ($state, $len, $level);
	while (<>) {
		($state, $len, $level) = /Flush:\s+(\d+)\s+(\d+)\s+(\d+)/ and last;
	}
#print "getnext: $state, $len, $level\n";
	return ($state, $len, $level);
}

sub got_bit($) {
	my $bit = shift;
	return unless defined $bit;
	$byte |= ($bit << $bit_pos++);
printf(">\t%d %8b %d\n", $bit, $byte, $bit_pos-1);
	if ($bit_pos == 4) {
		printf("got byte: %d %02X\n", $byte, $byte);
		$byte = 0;
		# $bit_pos = 7;
	}
	$bit_pos = 0 if $bit_pos == 8;
}

sub almost_same($$$) {	# only for positive values!
	my ($x, $y, $limit) = (shift, shift, shift);
	return '' if $x == 0 || $y == 0;
	my $coef = ($x >= $y) ? $x/$y : $y/$x ;
#printf("almost_same: %f %f %f |%s|\n", $x, $y, $coef, $coef <= $limit);
	return $coef <= $limit;
}

sub flush_packet() {
	$T = 0;
	print "flush_packet:";
	print "byte = $byte, pos = $bit_pos" unless $bit_pos == 4;
	print "\n";
}

sub preamble_detected() {
	my ($state, $len, $level);
#print "preamble_detected: start\n";
	while (1) {
		($state, $len, $level) = getnext();
		return undef unless defined $state;
		last if $state == 1;
	}
#print "preamble_detected: sync 1\n";
	my $pulse_count = 1;
	my $T_sum = $len;
	while (($state, $len, $level) = getnext()) {
		return undef unless defined $state;
		last unless almost_same($len, $T_sum/$pulse_count, 1.2);
		$pulse_count++;
		$T_sum += $len;
	}
#print "preamble_detected: pulse_count = $pulse_count\n";
	return 0 unless $pulse_count >= 8;
	return 0 unless $state == 0;
	$T = $T_sum/$pulse_count;
	return 0 unless almost_same($len, 2*$T, 1.2);
	$pulse_count = 1;
	while (($state, $len, $level) = getnext()) {
		return undef unless defined $state;
		last unless almost_same($len, 2*$T, 1.2);
		$pulse_count++;
		last if $pulse_count >= 4;
	}
#print "preamble_detected: ".($pulse_count==4?'FOUND!':'false')."\n";
	return $pulse_count == 4;
}

PACKET: while (1) {
	# printf ("%u %u %u\n", $state, $len, $level);
	my $res = preamble_detected();
	last unless defined $res;
	next unless $res;
	print "T=$T\n";
	my $bit = 0;
	while (my ($state, $len, $level) = getnext()) {
		last unless defined $state;
		if (almost_same($len, 2*$T, 1.2)) {
#print "\t\t\tL\n";
			$bit ^= 1;
			got_bit($bit);
		} elsif (almost_same($len, $T, 1.2)) {
			($state, $len, $level) = getnext();
			if (almost_same($len, $T, 1.2)) {
#print "\t\t\tS\n";
				got_bit($bit);
			} else {
print "Broken packet!\n";
				flush_packet();
				next PACKET;
			}
		} elsif ($len > 8*$T and $state == 0) {
			flush_packet();
			next PACKET;
		}
	}
}
