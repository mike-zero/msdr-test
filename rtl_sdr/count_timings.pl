#!/usr/bin/perl -w

use strict;

use Data::Dumper;

sub LEVEL_LOW_LIMIT() { 1000 }
sub MAX_DEVIATION_COEFF() { 1.2 }
sub TICKS_TIMEOUT() { 500 }

my $last_level = 0;
my @ccc = ({}, {});
my $count = 0;

# my @target = ([], []);

sub Flush() {
	return unless $count;
#	print Dumper \@ccc;
	my @target = ([], []);

	foreach my $state (0..$#ccc) {
		print "============ State: $state ============\n";
		TICK: foreach my $ticks (sort { $ccc[$state]->{$b} <=> $ccc[$state]->{$a} } keys %{$ccc[$state]}) {
			print "$ticks\t$ccc[$state]->{$ticks}\n";
			foreach my $tgt (@{$target[$state]}) {
				if ($ticks >= $tgt->{'low'} and $ticks <= $tgt->{'high'}) {
# print "Found: $tgt->{low} <= $ticks <= $tgt->{high}\n";
					$tgt->{'sum'} += $ticks * $ccc[$state]->{$ticks};
					$tgt->{'cnt'} += $ccc[$state]->{$ticks};
					$tgt->{'low'} = $tgt->{'sum'} / $tgt->{'cnt'} / MAX_DEVIATION_COEFF();
					$tgt->{'high'} = $tgt->{'sum'} / $tgt->{'cnt'} * MAX_DEVIATION_COEFF();
					next TICK;
				}
			}
			push @{$target[$state]}, {'sum'=>$ticks * $ccc[$state]->{$ticks}, 'cnt'=>$ccc[$state]->{$ticks}, 'low'=>$ticks/MAX_DEVIATION_COEFF(), 'high'=>$ticks*MAX_DEVIATION_COEFF()};
		}
	}
	print Dumper \@target;

	@ccc = ({}, {});
	$count = 0;
}

while (<>) {
	my ($state, $ticks, $level) = /Flush:\s+(\d+)\s+(\d+)\s+(\d+)/ or next;
#		print "$state, $ticks, $level\n";
#last;
#		if ($level <= $last_level*2 and $level >= $last_level/2 or $last_level == 0 and $level > LEVEL_LOW_LIMIT) {
	if ($state == 0 and $ticks >= TICKS_TIMEOUT()) {
		Flush();
	} else {
		$ccc[$state]->{$ticks}++;
		$count++;
	}

}

Flush();

