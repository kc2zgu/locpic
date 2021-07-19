#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Getopt::Std;
use LocPic::Track;
use LocPic::TrackDB;
use LocPic::Image;
use GIS::Distance;
use File::Basename;
use Statistics::Descriptive;

my %opts;
getopts('z:m:t:o:c:', \%opts);

sub HELP_MESSAGE {
    print "Usage: $0 [-m method] -t time [-z timezone] image\n";
}

my ($input) = @ARGV;
my $zone;

sub align_direct {
    die "direct alignment requires a single image as input\n"
      unless -f $input;
    my $image = LocPic::Image->new($input);

    my ($itime, $izone) = $image->get_time();
    my $iday = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day);
    my $camera = $image->get_camera();

    print "camera: $camera\n";
    print "image time: $itime\n";
    print "camera zone offset: $izone\n" if defined $izone;
    print "image date: $iday\n";

    my ($hour, $min, $sec) =
      $opts{t} =~ /(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/;
    my $gpsdt = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day,
                              hour => $hour, minute => $min, second => $sec);

    # set local timezone for GPS time
    $gpsdt->set_time_zone($zone);
    print "GPS local time: $gpsdt\n";
    # convert to UTC
    $gpsdt->set_time_zone('UTC');
    print "GPS UTC time: $gpsdt\n";

    my $offset = $gpsdt - $itime;
    my $offset_s = $offset->hours * 3600 + $offset->minutes * 60 + $offset->seconds;
    print "offset: $offset_s\n";
    
    if (defined $izone)
    {
        my $itime_utc = $itime - DateTime::Duration->new(seconds => $izone);
        print "camera UTC time: $itime_utc\n";
        my $roffset = $gpsdt - $itime_utc;
        my $roffset_s = $roffset->hours * 3600 + $roffset->minutes * 60 + $roffset->seconds;
        $roffset_s = -$roffset_s if $roffset->is_negative;
        print "reduced (UTC) offset: $roffset_s\n";
    }
}

sub align_vmin {
    my @images;
    if (-f $input)
    {
        @images = ($input);
    }
    elsif (-d $input)
    {
        opendir my $dir, $input;
        while (my $f = readdir $dir)
        {
            push @images, "$input/$f" if -f "$input/$f";
        }
    }

    my $offset_start = $opts{z} * -3600;
    my $trackdb = LocPic::TrackDB->new;
    my ($lasttrack, $track);
    my $gisd = GIS::Distance->new();
    my @offsetstats;
    for my $imagefile(sort @images)
    {
        my $image = LocPic::Image->new($imagefile);
        next unless defined $image;
        my $camera = $image->get_camera();

        if ($opts{c} && $camera !~ /$opts{c}/)
        {
            print "$imagefile: camera $camera skipped\n";
            next;
        }

        my $itime;
        eval
        {
            $itime = $image->get_time();
        };
        if ($@)
        {
            print "[$imagefile: internal error]\n";
            next;
        }
        print "$imagefile\n";
        for my $offsearch(-$opts{o} .. $opts{o})
        {
            #print "check offset $offsearch\n";
            my $offsetdt = DateTime::Duration->new(seconds => ($offset_start + $offsearch));
            my $gpstime = $itime + $offsetdt;
            my $trackfile = $trackdb->find_time($gpstime);
            unless (defined $trackfile)
            {
                printf "%-16s : %s NO TRACK\n",
                  basename($imagefile), $itime;
                next;
            }
            if ($trackfile ne $lasttrack)
            {
                print "[load track $trackfile]...";
                $track = LocPic::Track->new($trackfile);
                $lasttrack = $trackfile;
                my $pts = $track->points;
                print " $pts points\n";
            }
            my ($p1, $p2) = $track->find_points($gpstime);

            if (defined $p2)
            {
                my ($lat1, $lon1, $time1) = ($p1->lat, $p1->lon, $p1->time);
                my ($lat2, $lon2, $time2) = ($p2->lat, $p2->lon, $p2->time);

                #print "P1: $time1 $lat1 $lon1\n";
                #print "P2: $time2 $lat2 $lon2\n";

                my $intv = ($time2 - $time1)->seconds;
                #print "interval: $intv\n";
                my $dist = $gisd->distance($lat1, $lon1, $lat2, $lon2)->value('metre');
                #print "distance: $dist\n";
                my $vel = $dist/$intv;
                #printf "offs=%d, v=%.2f\n", $offsearch, $vel;
                $offsetstats[$offsearch + $opts{o}] = Statistics::Descriptive::Full->new
                  unless (defined $offsetstats[$offsearch + $opts{o}]);
                $offsetstats[$offsearch + $opts{o}]->add_data($vel);
            }
            else
            {
                #print "offs=$offsearch, no motion\n";
            }
        }
    }

    print "time offset stats:\n";
    for my $o(0..$#offsetstats)
    {
        printf("o=%4d, n=%4d, mean=%.2f, sd=%.2f   ",
               $offset_start - $opts{o} + $o,
               $offsetstats[$o]->count, $offsetstats[$o]->mean, $offsetstats[$o]->standard_deviation);
        my $nx = int($offsetstats[$o]->mean * 20);
        if ($nx > 40)
        {
            print ' ' x 41;
            print ">\n";
        }
        else
        {
            print ' ' x $nx;
            print "*\n";
        }
    }
}

# parse timezone
if (defined $opts{z})
{
    if ($opts{z} =~ /^-?\d+(?:\.\d+)?$/)
    {
        print "timezone: $opts{z} hours\n";
    }
    elsif ($opts{z} =~ /^([\+\-])?(\d\d?):(\d\d)(?::(\d\d))?$/)
    {
        print "timezone: $opts{z} h/m/s\n";
        $zone = DateTime::TimeZone->new(name => $opts{z});
    }
    elsif (DateTime::TimeZone->is_valid_name($opts{z}))
    {
        print "named timezone: $opts{z}\n";
        $zone = DateTime::TimeZone->new(name => $opts{z});
    }
}
else
{
    print "timezone: defaulting to local\n";
    $zone = DateTime::TimeZone->new(name => 'local');
}

unless (defined $zone)
{
    die "No local timezone specified or detected\n";
}

if ($opts{m} eq 'direct')
{
    align_direct();
}
elsif ($opts{m} eq 'vmin')
{
    align_vmin();
}
elsif (!defined $opts{m})
{
    align_direct();
}
else
{
    die "unsupported alignment method '$opts{m}'\n";
}
