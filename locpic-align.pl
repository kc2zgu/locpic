#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use LocPic::Track;
use LocPic::TrackDB;
use LocPic::Image;

my ($imagefile, $gpstime, $zone) = @ARGV;

my $image = LocPic::Image->new($imagefile);

my $itime = $image->get_time();
my $iday = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day);
my $camera = $image->get_camera();

print "camera: $camera\n";
print "image time: $itime\n";
print "image date: $iday\n";

my ($hour, $min, $sec) =
  $gpstime =~ /(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/;
my $gpsdt = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day, hour => $hour, minute => $min, second => $sec);

print "GPS local time: $gpsdt\n";
$gpsdt -= DateTime::Duration->new(hours => $zone);
print "GPS UTC time: $gpsdt\n";

my $offset = $gpsdt - $itime;
my $offset_s = $offset->hours * 3600 + $offset->minutes * 60 + $offset->seconds;
print "offset: $offset_s\n";
