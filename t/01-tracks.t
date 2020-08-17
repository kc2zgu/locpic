# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 16;

use LocPic::Track;
use Path::Tiny;

my $assets = path($ENV{LOCPIC_ASSETS});

my $track = new_ok('LocPic::Track', $assets->child('2012-08-25 21.27.22 Day.gpx'));

is($track->points, 18);
is($track->start_time, '2012-08-26T01:27:22');
is($track->end_time, '2012-08-26T01:27:56');

$track = new_ok('LocPic::Track', $assets->child('2008-06-01-15-52-22.gpx'));

is($track->points, 155);
is($track->start_time, '2008-06-01T15:51:26');
is($track->end_time, '2008-06-01T15:56:20');

$track = new_ok('LocPic::Track', $assets->child('20100410-170111.gpx'));

is($track->points, 34);
is($track->start_time, '2010-04-10T21:01:16');
is($track->end_time, '2010-04-10T21:02:07');

$track = new_ok('LocPic::Track', $assets->child('2020-08-16_12-49_Sun.gpx'));

is($track->points, 449);
is($track->start_time, '2020-08-16T16:49:34');
is($track->end_time, '2020-08-16T17:01:56');
