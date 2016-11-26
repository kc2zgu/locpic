#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use LocPic::Track;
use LocPic::Database;
use LocPic::TrackDB;
use Getopt::Std;

my %opts;
getopts('d:', \%opts);

if ($opts{d})
{
    LocPic::Database->set_dbpath($opts{d});
}

my @trackfiles = @ARGV;

my $trackdb = LocPic::TrackDB->new;

for my $file(@trackfiles)
{
    eval
    {
        my $mtime = (stat($file))[9];
        if (my $itime = $trackdb->find_file($file))
        {
            if ($itime > $mtime)
            {
                print "$file already indexed\n";
                next;
            }
        }

        my $track = LocPic::Track->new($file);
        unless (defined $track)
        {
            print "no tracks in $file\n";
            next;
        }

        #print "track range: $track->{start_time} - $track->{end_time}\n";
        my $point = $track->get_point(0);
        #print "point: $point->{lat} $point->{lon}\n";

        $trackdb->add_track($track);
    };
}
