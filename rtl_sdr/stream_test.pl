#!/usr/bin/perl -w

use strict;

my $filename = shift || '-';

my $bufsize = 2 * 10240;
my $buf = 0 x $bufsize;

my %hh = ();

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	# syswrite(F, $buf, length($buf));
	for my $i (0..(length($buf)/2-1)) {
		$hh{substr($buf, $i*2, 2)}++;
	}
}
close F;
foreach (sort { $hh{$b} <=> $hh{$a} } keys %hh) {
	# printf("%X %X\t%d\n", unpack('C*', $_), $hh{$_});
	printf("%d %d\t%d\n", ( map { $_ - 0x80 } unpack('C*', $_) ), $hh{$_});
}