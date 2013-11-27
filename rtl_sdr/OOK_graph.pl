#!/usr/bin/perl -w

use strict;
use GD;

my @buf;
my $max_level = 0;
my $total_len = 0;
my $width_coef = 0.1;

while (<>) {
	my ($state, $len, $level) = /Flush:\s+(\d+)\s+(\d+)\s+(\d+)/ or next;
	next unless defined $state;
	$len *= $width_coef;
	push @buf, [$state, $len, $level];
	$max_level = $level if $level > $max_level;
	$total_len += $len;
}

my ($size_x, $size_y) = (int($total_len) + 1, 400);

my $im = new GD::Image($size_x, $size_y);

my  $black = $im->colorAllocate(0,0,0);       
my  $white = $im->colorAllocate(255,255,255);
#my  $red = $im->colorAllocate(255,0,0);      
#my  $blue = $im->colorAllocate(0,0,255);

#    $im->transparent($black);
#    $im->interlaced('true');

#my $i = 10;

my ($x, $x_prev) = (0, 0);
my ($y, $y_prev) = (0, 0);

foreach my $i (0..$#buf) {
	$x += $buf[$i][1];
	# $y = $buf[$i][0] ? $size_y * 0.2 : $size_y * 0.8;
	$y = $size_y - int($buf[$i][2] / $max_level * $size_y * 0.6 + $size_y * 0.2);
#warn "$x, $y\n";
	if ($i > 0) {
		$im->line($x_prev, $y_prev, $x_prev, $y, $white);
	}
	$im->line($x_prev, $y, int($x), $y, $white);
	$x_prev = int($x);
	$y_prev = $y;
}

binmode STDOUT;
print $im->png;
