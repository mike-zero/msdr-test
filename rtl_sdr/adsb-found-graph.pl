#!/usr/bin/perl -w

use strict;
use GD;

my ($size_x, $size_y) = (1200, 600);

my $im = new GD::Image($size_x, $size_y);

my  $white = $im->colorAllocate(255,255,255);
my  $black = $im->colorAllocate(0,0,0);       
my  $red = $im->colorAllocate(255,0,0);      
my  $blue = $im->colorAllocate(0,0,255);

#    $im->transparent($black);
#    $im->interlaced('true');

my $i = 10;

while (<>) {
	next unless /^\s+(\d+)/;
	my $odd = $i & 1;
	$im->rectangle(10 + $i*3 + 2*$odd, $size_y - 10 - 4 * $1, 10 + $i*3 + 1 + 2*$odd, $size_y - 10, $odd ? $red : $blue);
	++$i;
}

binmode STDOUT;
print $im->png;
