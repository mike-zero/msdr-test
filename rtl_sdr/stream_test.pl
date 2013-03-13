#!/usr/bin/perl -w

use strict;
use integer;

my $filename = shift || '-';

my $bufsize = 2 * 16384;
my $buf = 0 x $bufsize;

my %hh = ();
my ($avg_i, $avg_q, $avg_i_24, $avg_q_24) = (0x8000, 0x8000, 0x800000, 0x800000);
my ($i, $q);

sub correct_avg() {
	# my $buf = shift;
	my ($cur_i_sum, $cur_q_sum) = (0, 0);
	foreach (0..(length($buf)/2-1)) {
		$i = ord(substr($buf, $_*2, 1));
		$q = ord(substr($buf, $_*2+1, 1));
		$cur_i_sum += $i;
		$cur_q_sum += $q;
		printf("%12d\n", ($i-$avg_i)**2 + ($q-$avg_q)**2);
	}
	if (length($buf) > 0) {
		$avg_i = $cur_i_sum*2/length($buf); # ($avg_i * 7 + $cur_i_sum*2/length($buf)) >> 3;
		$avg_q = $cur_q_sum*2/length($buf); # ($avg_q * 7 + $cur_q_sum*2/length($buf)) >> 3;
	}
}

warn "Start: ".(scalar localtime(time));

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	my ($cur_i_sum, $cur_q_sum) = (0, 0);
	my $j = 0;
	# correct_avg();

	foreach my $s (0..(length($buf)/2-1)) {
		$i = ord(substr($buf, $s*2, 1));
		$q = ord(substr($buf, $s*2 + 1, 1));
		$cur_i_sum += $i;
		$cur_q_sum += $q;
		if (++$j == 256) {
			$avg_i_24 = $avg_i_24 - ($avg_i_24 >> 8) + $cur_i_sum;
			$avg_q_24 = $avg_q_24 - ($avg_q_24 >> 8) + $cur_q_sum;
			$avg_i = $avg_i_24 >> 8;
			$avg_q = $avg_q_24 >> 8;
			$j = 0;
			$cur_i_sum = 0;
			$cur_q_sum = 0;
		}
		$i = ($i << 8) - $avg_i;
		$q = ($q << 8) - $avg_q;
# my $amp = ($i*$i+$q*$q) >> 16;
my $amp = int(sqrt($i*$i+$q*$q)) >> 8;
#		print "$i\t$q\t".(($i*$i+$q*$q) >> 16)."\n";
		print "$i\t$q\t$amp\t".('*' x ($amp <= 200 ? $amp : 200))."\n";
#		$hh{substr($buf, $s*2, 2)}++;
	}
	# print "Avg: $avg_i, $avg_q\n";
	# last;
}
close F;

#foreach (sort { $hh{$b} <=> $hh{$a} } keys %hh) {
#	# printf("%X %X\t%d\n", unpack('C*', $_), $hh{$_});
#	($i, $q) = (ord(substr($_, 0, 1)) - $avg_i, ord(substr($_, 1, 1)) - $avg_q);
#	printf("I:%6.2f Q:%6.2f R:%10.2f Cnt:%12d\n", $i, $q, $i*$i+$q*$q, $hh{$_});
#	# printf("%d %d\t%d\n", ( map { $_ - 0x80 } unpack('C*', $_) ), $hh{$_});
#}

warn "Stop:  ".(scalar localtime(time));
