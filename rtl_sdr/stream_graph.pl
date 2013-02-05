#!/usr/bin/perl -w

use strict;
use integer;
use GD;

my $filename = shift || '-';

my $bufsize = 2 * 10240;
my $buf = 0 x $bufsize;

my %hh = ();
my ($i, $q);
my $max_val = 0;

sub hsv2rgb($$$) {
	my ($h, $s, $v) = @_;
	$s /= 256;
	return ($v, $v, $v) if $s == 0;
	$h /= (256 / 6);
	my $i = int($h);
	my $f = $h - $i;
	my $p = int($v * (1 - $s));
	my $q = int($v * (1 - $s * $f));
	my $t = int($v * (1 - $s * (1 - $f)));
	return  $i == 0 ? ($v,$t,$p) :
		$i == 1 ? ($q,$v,$p) :
		$i == 2 ? ($p,$v,$t) :
		$i == 3 ? ($p,$q,$v) : 
		$i == 4 ? ($t,$p,$v) : ($v,$p,$q);
}

my $compress_coeff = 1.4;
my $compress_lim = 192;
my $compress_max = 255;
sub compress($) {
	my $x = shift;
	$x *= $compress_coeff;
	if ($x >= $compress_lim) {
		$x = $compress_lim + ($x-$compress_lim)/ ($compress_max*$coeff-$compress_lim) * ($compress_max-$compress_lim);
	}
	return $x;	
}

warn "Start: ".(scalar localtime(time));

open F, $filename;
binmode(F);
while (sysread(F, $buf, $bufsize)) {
	foreach my $s (0..(length($buf)/2-1)) {
		$i = ord(substr($buf, $s*2, 1));
		$q = ord(substr($buf, $s*2 + 1, 1));
#		$cur_i_sum += $i;
#		$cur_q_sum += $q;
#		if (++$j == 256) {
#			$avg_i_24 = $avg_i_24 - ($avg_i_24 >> 8) + $cur_i_sum;
#			$avg_q_24 = $avg_q_24 - ($avg_q_24 >> 8) + $cur_q_sum;
#			$avg_i = $avg_i_24 >> 8;
#			$avg_q = $avg_q_24 >> 8;
#			$j = 0;
#			$cur_i_sum = 0;
#			$cur_q_sum = 0;
#		}
#		$i = ($i << 8) - $avg_i;
#		$q = ($q << 8) - $avg_q;
#		print "$i\t$q\t".(($i*$i+$q*$q) >> 16)."\n";
		$max_val = $hh{$i}{$q} if ++$hh{$i}{$q} > $max_val;
	}
	# print "Avg: $avg_i, $avg_q\n";
	# last;
}
close F;

no integer;

my $pixel_size = 2;
my ($size_x, $size_y) = (256 * $pixel_size, 256 * $pixel_size);
my $im = new GD::Image($size_x, $size_y, 1);
my $temp_color;

foreach my $i (sort { $hh{$b} <=> $hh{$a} } keys %hh) {
	foreach my $q (sort { $hh{$i}{$b} <=> $hh{$i}{$a} } keys %{$hh{$i}}) {
		$temp_color = $im->colorAllocate(hsv2rgb($hh{$i}{$q} / $max_val, 256, 255));
		$im->rectangle($i * $pixel_size, $q * $pixel_size, ($i+1) * $pixel_size - 1, ($q+1) * $pixel_size - 1, $temp_color);
	}
}

binmode STDOUT;
print $im->png;

warn "Stop:  ".(scalar localtime(time));
