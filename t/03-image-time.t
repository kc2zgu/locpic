# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 11;

use LocPic::Image;
use Path::Tiny;

my $assets = path($ENV{LOCPIC_ASSETS});

my $image = new_ok('LocPic::Image', [$assets->child('IMG_0673.JPG')]);

$image = new_ok('LocPic::Image', [$assets->child('IMG_0673.JPG')->stringify]);

my ($time, $zone) = $image->get_time;

is($time, '2019-07-11T18:10:51');
is($zone, -14400);

$image = new_ok('LocPic::Image', [$assets->child('IMG_7457.JPG')]);
($time, $zone) = $image->get_time;

is($time, '2016-03-05T15:19:52');
is($zone, -18000);

$image = new_ok('LocPic::Image', [$assets->child('P1040326.JPG')]);
($time, $zone) = $image->get_time;

is($time, '2016-03-06T12:16:12');

$image = new_ok('LocPic::Image', [$assets->child('P5241425.JPG')]);
($time, $zone) = $image->get_time;

is($time, '2017-05-24T18:19:30');
