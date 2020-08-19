# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 9;

use LocPic::Image;
use Path::Tiny;

my $assets = path($ENV{LOCPIC_ASSETS});

my $image = new_ok('LocPic::Image', [$assets->child('IMG_8025.JPG')]);

is(sprintf('%.6f', $image->get_location->lat), '43.125685');
is(sprintf('%.6f', $image->get_location->lon), '-77.618096');

$image = new_ok('LocPic::Image', [$assets->child('IMG_20140816_123306.jpg')]);

is(sprintf('%.6f', $image->get_location->lat), '43.116796');
is(sprintf('%.6f', $image->get_location->lon), '-77.667788');

$image = new_ok('LocPic::Image', [$assets->child('20190324_090810.jpg')]);

is(sprintf('%.6f', $image->get_location->lat), '43.714050');
is(sprintf('%.6f', $image->get_location->lon), '-74.121981');
