# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 8;

use LocPic::Image;
use Path::Tiny;

my $assets = path($ENV{LOCPIC_ASSETS});
my $temp = path($ENV{LOCPIC_TMP});

my $srcimage = $assets->child('IMG_0673-notag.JPG');

my $testimage = $srcimage->copy($temp->child('IMG_0673.JPG'));

my $image = LocPic::Image->new($testimage);

is($image->get_location, undef);

my $point = LocPic::Point->new(lat => 43.150561, lon => -77.603542, ele => 100);

is($point->lat, 43.150561);
is($point->lon, -77.603542);

$image->set_location($point);
is($image->{metadirty}, 1);
eval {$image->write_meta();};
is($image->{metadirty}, 0);

$image = undef;

$image = LocPic::Image->new($testimage);

isnt($image->get_location, undef);
if (defined $image->get_location)
{
    is(sprintf('%.6f', $image->get_location->lat), '43.150561');
    is(sprintf('%.6f', $image->get_location->lon), '-77.603542');
}
else
{
    fail('location undefined');
    fail('location undefined');
}
