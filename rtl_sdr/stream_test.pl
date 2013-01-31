#!/usr/bin/perl -w

use strict;

my $filename = shift || '-';

my $bufsize = 2 * 1024000;
my $buf = 0 x $bufsize;

my %hh = ();
my ($avg_i, $avg_q) = (0, 0);

sub correct_avg($) {
	my $buf = shift;
	my ($cur_i_sum, $cur_q_sum, $cnt) = (0, 0, 0);
	for my $i (0..(length($$buf)/2-1)) {
		$cur_i_sum += unpack('C*', substr($$buf, $i*2, 1));
		$cur_q_sum += unpack('C*', substr($$buf, $i*2+1, 1));
		$cnt++;
	}
	($avg_i, $avg_q) = ($cur_i_sum/$cnt, $cur_q_sum/$cnt) if $cnt > 0;
}

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	for my $i (0..(length($buf)/2-1)) {
		$hh{substr($buf, $i*2, 2)}++;
	}
	correct_avg(\$buf);
	print "Avg: $avg_i, $avg_q\n";
}
close F;
foreach (sort { $hh{$b} <=> $hh{$a} } keys %hh) {
	# printf("%X %X\t%d\n", unpack('C*', $_), $hh{$_});
	printf("%d %d\t%d\n", ( map { $_ - 0x80 } unpack('C*', $_) ), $hh{$_});
}
