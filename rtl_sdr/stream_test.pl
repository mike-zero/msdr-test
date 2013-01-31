#!/usr/bin/perl -w

use strict;

my $filename = shift || 'aaa.bin';

my $bufsize = 10240;
my $buf = 0 x $bufsize;

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	# syswrite(F, $buf, length($buf));
	print ord(substr($buf,1,1)),"\n";
}
close F;