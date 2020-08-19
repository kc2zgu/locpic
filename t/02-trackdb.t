# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 10;

use LocPic::Track;
use LocPic::TrackDB;
use Path::Tiny;

my $assets = path($ENV{LOCPIC_ASSETS});
my $temp = path($ENV{LOCPIC_TMP});

my $dbfile = $temp->child('tracks.db');

LocPic::Database->set_dbpath($dbfile);

# create new track DB
my $trackdb = new_ok('LocPic::TrackDB');

# test that file exists
ok(-f $dbfile);

# close and reopen the same DB file
$trackdb = undef;
$trackdb = new_ok('LocPic::TrackDB');

# search for a nonexistent file
is($trackdb->find_file('does_not_exist.gpx'), undef);

# add a track
my @tracks = ($assets->child('2020-08-09 113303.gpx'));

ok($trackdb->add_track(LocPic::Track->new($tracks[0])));

# read the track record
isnt($trackdb->find_file('2020-08-09 113303.gpx'), 0);

# search by time, equal to first point
my $findtime = '2020-08-09T15:04:22';

my ($foundtrack) = $trackdb->find_time($findtime);
is(path($foundtrack)->canonpath, $tracks[0]->canonpath);

# search by time, between first and last
$findtime = '2020-08-09T15:05:39';

($foundtrack) = $trackdb->find_time($findtime);
is(path($foundtrack)->canonpath, $tracks[0]->canonpath);

# search by time, after last, within maxfiff
$findtime = '2020-08-09T15:35:00';

($foundtrack) = $trackdb->find_time($findtime);
is(path($foundtrack)->canonpath, $tracks[0]->canonpath);

# search by time, after last, beyond maxdiff
$findtime = '2020-08-09T18:00:00';

($foundtrack) = $trackdb->find_time($findtime);
is($foundtrack, undef);
