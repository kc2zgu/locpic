#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use LocPic::Image;

my @images = @ARGV;

for my $imagefile(@images)
{
    my $image = LocPic::Image->new($imagefile);

    print "$imagefile\n";
    my $time = $image->get_time();
    print " image time: $time\n";
    my $camera = $image->get_camera;
    print " camera: $camera\n";
}
