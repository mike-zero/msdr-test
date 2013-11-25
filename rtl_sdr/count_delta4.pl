#!/usr/bin/perl -w

use strict;

sub AGC_HOLD() { 50 } # ticks before falling down
sub AGC_DEC_COEFF() { 0.995 } # ticks before falling down
sub AGC_INC_COEFF() { 1.05 } # ticks before falling down
sub IMPULSE_MIN_LENGTH() { 10 }
sub TRANSMISSION_TIMEOUT() { 900 }	# ticks of 0
sub SMOOTH_BUF() { 3 }

my $prev = 0;
my $agc_level = 1;
my $agc_ticks = 0;
my $state = -1;
my $state_ticks = 0;
my $peak = -1;
my $prev_state = -1;
my $prev_state_ticks = 0;
my $prev_peak = 0;

my @vals_buf = ();
push @vals_buf, 0 while scalar @vals_buf < SMOOTH_BUF();

my @impulse_buf;
my @front_buf;

sub flush($$$) {
	my ($state, $ticks, $peak) = @_;
	print "\t\t\t\t\t\t\t\t\t\tFlush: $state\t$ticks\t$peak\n";
	push @impulse_buf, [$state, $ticks, $peak];
}

sub big_flush() {
	print "\nSTOP: \n";
	while (my $impulse = shift @impulse_buf) {
		printf(">> %d\t%d\t%d\n", @$impulse);
	}
}

while (<>) {
	next unless /amp=\s*(\d+)/;
	my $val = $1;

	# smoothing begin
	push @vals_buf, $val;
	if ($vals_buf[1] > $vals_buf[0] && $vals_buf[1] > $vals_buf[2]) {
		$vals_buf[1] = $vals_buf[0] > $vals_buf[2] ? $vals_buf[0] : $vals_buf[2];
	} elsif ($vals_buf[1] < $vals_buf[0] && $vals_buf[1] < $vals_buf[2]) {
		$vals_buf[1] = $vals_buf[0] < $vals_buf[2] ? $vals_buf[0] : $vals_buf[2];
	}
	$val = shift @vals_buf;
	# smoothing end

	# AGC begin
	if ($val >= $agc_level) {
		$agc_level = $val;
		$agc_ticks = 0;
	} else {
		$agc_ticks++;
		if ($agc_ticks >= AGC_HOLD() && $val < $agc_level/4) {
			$agc_level *= AGC_DEC_COEFF();
		}
	}
	# AGC end

	my $bit = $val > ($agc_level>>1) ? 1 : 0;
	if ($bit != $state) {
		if ($bit == $prev_state && $state_ticks <= IMPULSE_MIN_LENGTH()) {	# it was a short impulse (noise), we will ignore it
#			print "Noise!\n";
			# $agc_level *= AGC_INC_COEFF() if $state == 1;
			$prev_state = -1;
			$state_ticks += $prev_state_ticks;
			$prev_state_ticks = 0;
			$peak = $prev_peak; # if $prev_peak > $peak;
			$prev_peak = 0;
		} else {	# state change
			# print "\t\t\t\t\t\t\t\t\t\tFlush: $prev_state\t$prev_state_ticks\n" unless $prev_state == -1;
			unless ($prev_state == -1) {
				if ($prev_state == 0 && $state == 1) {
					FRONT_CUT:
					while (my $aa = pop @front_buf) {
						my ($val, $ticks) = @$aa;
						if ($val < ($peak>>1)) {
							# print "vvvvvv front_buf:\t$val\t$ticks\n";
							$prev_state_ticks += $ticks;
							$state_ticks -= $ticks;
							last FRONT_CUT;
						}
					}
				}
				flush($prev_state, $prev_state_ticks, $prev_peak);
			}
			$prev_state = $state;
			$prev_state_ticks = $state_ticks;
			$state_ticks = 0;
			$prev_peak = $peak;
			$peak = -1;
			@front_buf = ();
		}
		$state = $bit;
	}

	$state_ticks++;

	# record the front steps to be able to cut off its lower part later
	if ($state == 1 && $val > $peak) {
		push @front_buf, [$val, $state_ticks];
		# print "^^^^^^ front_buf:\t$val\t$state_ticks\n";
		$peak = $val;
	} elsif ($state == 0 && ($peak == -1 || $val < $peak)) {
		$peak = $val;
	}

	if ($state == 0 && $state_ticks == TRANSMISSION_TIMEOUT) {
		unless ($prev_state == -1) {
			# print "\t\t\t\t\t\t\t\t\t\tFlush: $prev_state\t$prev_state_ticks\n";
			flush($prev_state, $prev_state_ticks, $prev_peak);
			$prev_state = -1;
			$prev_state_ticks = 0;
			$prev_peak = 0;
		}
		big_flush();
	}
	printf("v:%7d a:%7d %7d b:%7d s:%7d %7d p:%7d %7d %s\n", $val, $agc_level, $agc_ticks, $bit, $state, $state_ticks, $prev_state, $prev_state_ticks, $bit ? '=' x int(100*$val/$agc_level) : '.' x int(100*$val/$agc_level));
#	$prev = $val;
}
