#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use LocPic::Track;
use LocPic::TrackDB;
use LocPic::Image;
use LocPic::Debug;
use File::Basename;
use Getopt::Std;

my %opts;

getopts('i:c:d:g:o:t:l:nfbh', \%opts);

sub usage {
    print "Usage: $0 options\n\n";

    print "  -i file|directory    input image(s)\n";
    print "  -c camera            restrict to camera\n";
    print "  -d trackdb           track database path\n";
    print "  -g gpxfile           single GPX track\n";
    print "  -o offset            time offset\n";
    print "  -t seconds           maximum interpolation interval\n";
    print "  -l level             debug message level\n";
    print "  -n                   dry run (no file updates)\n";
    print "  -f                   force updates\n";
    print "  -b                   save backup copies of images\n";
}

if (exists $opts{h})
{
    usage;
    exit 0;
}

if (exists $opts{l})
{
    LocPic::Debug->set_level($opts{l});
}

my ($trackdb, $lasttrack, $track, $offsetdt);

my %stats;
sub add_stat {
    my $stat_type = shift;
    if (exists $stats{$stat_type})
    {
        $stats{$stat_type}++;
    }
    else
    {
        $stats{$stat_type} = 1
    }
    #print "$stat_type count: $stats{$stat_type}\n";
}

sub align_image {
    my $image = LocPic::Image->new($_[0]);
    unless (defined $image)
    {
        print "not an image: $_[0]\n";
        add_stat('noimage');
        return;
    }

    add_stat('total');

    my $itime;
    eval
    {
        $itime = $image->get_time();
    };
    if ($@)
    {
        print "[$_[0]: internal error]\n";
        add_stat('error');
        return;
    }
    my $gpstime = $itime + $offsetdt;
    my $camera = $image->get_camera();
    local $| = 1;

    if ($opts{c} && $camera !~ /$opts{c}/)
    {
        printf "%-16s (%-24.24s): %s (camera skipped)\n",
          basename($_[0]), $camera, $itime;
        add_stat('camskip');
        return;
    }

    #print "camera time: $itime\n";
    #print "GPS time: $gpstime\n";

    if (defined $trackdb)
    {
        my $trackfile = $trackdb->find_time($gpstime);
        unless (defined $trackfile)
        {
            printf "%-16s (%-24.24s): %s NO TRACK\n",
              basename($_[0]), $camera, $itime;
            add_stat('notrack');
            return;
        }
        if ($trackfile ne $lasttrack)
        {
            print "[load track $trackfile]...";
            $track = LocPic::Track->new($trackfile);
            $lasttrack = $trackfile;
            my $pts = $track->points;
            print " $pts points\n";
        }
    }

    my ($p1, $p2) = $track->find_point($gpstime);

    my ($lat1, $lon1, $time1) = ($p1->lat, $p1->lon, $p1->time);
    if (defined $p2)
    {
        my ($lat2, $lon2, $time2) = ($p2->lat, $p2->lon, $p2->time);

        #print "nearest points: $time1 $lat1 $lon1, $time2 $lat2, $lon2\n";
        my $intv = ($time2 - $time1)->seconds;
        print "interval: $intv\n";
        my $ipos = ($gpstime - $time1)->seconds / $intv;
        #print "interpolate: $ipos\n";
        $lat1 = ($lat2 - $lat1) * $ipos + $lat1;
        $lon1 = ($lon2 - $lon1) * $ipos + $lon1;
    }
    else
    {
        LocPic::Debug->_debug(1 => "nearest point: $time1 $lat1 $lon1");
        #return;
    }

    #print "final location: $lat1 $lon1\n";
    printf "%-16s (%-24.24s): %s -> %s: %10.5f,%10.5f",
      basename($_[0]), $camera, $itime, $gpstime, $lat1, $lon1;
    if (my $point = $image->get_location && !exists $opts{f})
    {
        #print "existing location: $point->{lat} $point->{lon}\n";
        print " [skip]\n";
        add_stat('skip');
    }
    else
    {
        unless (exists $opts{n})
        {
            $image->set_location(LocPic::Point->new(lat => $lat1, lon => $lon1));
            $image->set_tag_hints(Track => basename($lasttrack), Offset => $opts{o}, GPSTime => $gpstime);
            print " [W]";
            $image->write_meta($opts{b});
            add_stat('tag');
        }
        print "\n";
    }
}

if (exists $opts{o})
{
    $offsetdt = DateTime::Duration->new(seconds => $opts{o});
}
else
{
    warn "no offset specified with -o, using 0\n";
    $offsetdt = DateTime::Duration->new(seconds => 0);
}

if (exists $opts{d})
{
    LocPic::Database->set_dbpath($opts{d});
}

if (exists $opts{g})
{
    $track = LocPic::Track->new($opts{g});
}
else
{
    $trackdb = LocPic::TrackDB->new;
    if (exists $opts{t})
    {
        $trackdb->{maxdiff} = $opts{t};
    }
}

if (-d $opts{i})
{
    opendir my $dir, $opts{i};
    while (my $file = readdir $dir)
    {
        my $path = "$opts{i}/$file";
        eval {
            align_image($path) if -f $path;
        };
        if ($@)
        {
            print "$file: Error: $@\n";
            add_stat('error');
        }
    }

    print "Images found:      $stats{total}\n";
    print "Non-image files:   $stats{noimage}\n" if $stats{noimage};
    print "Tag written:       $stats{tag}\n" if $stats{tag};
    print "Already tagged:    $stats{skip}\n" if $stats{skip};
    print "Camera skipped:    $stats{camskip}\n" if $stats{camskip};
}
else
{
    align_image($opts{i});
}
