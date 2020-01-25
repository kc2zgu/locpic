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
use Gtk3 '-init';

my $builder = Gtk3::Builder->new();
$builder->add_from_file("$FindBin::Bin/locpic-gui.ui");

my $window = $builder->get_object('window_main');
$builder->connect_signals(undef);

$window->signal_connect(destroy => sub {Gtk3::main_quit});

$window->show_all();

my ($image, $itime, $izone, $images_store, $offset_s, $offsetdt, $offsetdt_r, @images, $lasttrack, $track);
my $trackdb = LocPic::TrackDB->new;

sub create_model {
    my $lstore =
        Gtk3::ListStore->new( 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');

    return $lstore;
}

sub add_column {
    my ($treeview, $index, $name) = @_;

    my $renderer = Gtk3::CellRendererText->new;
    my $column = Gtk3::TreeViewColumn->new_with_attributes($name, $renderer, text => $index);
    $column->set_sizing('autosize');
    $treeview->append_column($column);
}

$images_store = create_model();
my $tree = $builder->get_object('tree_images');
$tree->set_model($images_store);
add_column($tree, 0, 'Image File');
add_column($tree, 1, 'Camera Time');
add_column($tree, 2, 'GPS Time');
add_column($tree, 3, 'Track');
add_column($tree, 4, 'Location');

Gtk3::main();

sub file_refimg_set {
    my $filebtn = shift;
    my $filename = $filebtn->get_filename();

    print "Reference image selected: $filename\n";

    my $img = $builder->get_object('img_refimg');
    $img->set_from_file($filename);

    # needs to return to event loop for size to update
    #my $viewport = $img->get_parent();
    #my $view_h = $viewport->get_hadjustment();
    #print "Horiz scroll range: @{[$view_h->get_lower()]} - @{[$view_h->get_upper()]}\n";
    #$view_h->set_value(($view_h->get_upper() - $view_h->get_lower) / 2);
    #print "Horiz scroll value: @{[$view_h->get_value]}\n";

    $image = LocPic::Image->new($filename);
    ($itime, $izone) = $image->get_time();

    $builder->get_object('label_cam_time')->set_label(sprintf '%02d:%02d:%02d', $itime->hour, $itime->minute, $itime->second);
}

sub gps_time_changed {
    return unless defined $itime;

    my $iday = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day);
    my $gpsdt = DateTime->new(year => $itime->year, month => $itime->month, day => $itime->day,
                              hour => $builder->get_object('adjustment_hr')->get_value,
                              minute => $builder->get_object('adjustment_min')->get_value,
                              second => $builder->get_object('adjustment_sec')->get_value);
    $gpsdt -= DateTime::Duration->new(hours => $builder->get_object('adjustment_tz_hr')->get_value);

    print "GPS local time: $gpsdt\n";

    my $offset = $gpsdt - $itime;
    $offset_s = $offset->hours * 3600 + $offset->minutes * 60 + $offset->seconds;
    $builder->get_object('label_time_offset')->set_label($offset_s);
}

sub save_offset {
    $builder->get_object('adjustment_offset')->set_value($offset_s);
}

sub clear_images {
    $images_store->clear();
    @images = ();
}

sub set_progress {
    my $p = shift;
    print "Progress: $p\n";
    $builder->get_object('progress')->set_fraction($p);
}

sub tag_image_set {
    my $filebtn = shift;
    my $filename = $filebtn->get_filename();

    open_tag_image($filename);
}

sub tag_dir_set {
    my $filebtn = shift;
    my $dirname = $filebtn->get_filename();

    opendir my $dir, $dirname;
    my @newimages;
    while (my $file = readdir $dir)
    {
        my $path = "$dirname/$file";
        push @newimages, $path unless -d $path;
    }
    closedir $dir;
    my $n = 0;
    for my $i(@newimages)
    {
        open_tag_image($i);
        Glib::MainContext::iteration(undef, 0);
        set_progress((++$n)/@newimages);
    }
    set_progress(0);
}

sub open_tag_image {
    my $file = shift;

    print "Loading image $file\n";

    my $image = LocPic::Image->new($file);
    if (defined $image)
    {
        my ($itime, $izone);
        eval
        {
            ($itime, $izone) = $image->get_time();
            my $loc = 'Not set';
            if (my $point = $image->get_location)
            {
                $loc = sprintf '%10.5f, %10.5f', $point->{lat}, $point->{lon};
            }
            my $iter = $images_store->append();
            $images_store->set($iter =>
                               0 => basename($file),
                               1 => $itime,
                               2 => '??',
                               3 => 'None',
                               4 => $loc);
            push @images, $image;
        }
    }
}

sub find_location {
    my $image = shift;
    my ($itime, $izone, $gpstime);

    ($itime, $izone) = $image->get_time();
    if (defined $izone)
    {
        $gpstime = $itime - DateTime::Duration->new(seconds => $izone) + $offsetdt_r;
    }
    else
    {
        $gpstime = $itime + $offsetdt;
    }

    if (defined $trackdb)
    {
        my $trackfile = $trackdb->find_time($gpstime);
        unless (defined $trackfile)
        {
            #printf "%-16s (%-24.24s): %s NO TRACK\n",
            #  basename($_[0]), $camera, $itime;
            #add_stat('notrack');
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
    return LocPic::Point->new(lat => $lat1, lon => $lon1);
}

sub tag_dryrun {
    if (@images)
    {
        $offset_s = $builder->get_object('adjustment_offset')->get_value();
        $offsetdt = DateTime::Duration->new(seconds => $offset_s);
        print "clock offset: $offset_s\n";
        my $offset_r = $offset_s % 1800;
        $offset_r -= 1800 if $offset_r > 900;
        print "reduced offset: $offset_r\n";
        $offsetdt_r = DateTime::Duration->new(seconds => $offset_r);

        my $iter = $images_store->get_iter_first();
        for my $i(0..$#images)
        {
            print "Image: $images[$i]\n";
            my $loc = find_location($images[$i]);
            my $locstr = sprintf '%10.5f, %10.5f', $loc->{lat}, $loc->{lon};
            $images_store->set($iter, 2 => $i, 4 => $locstr);
            set_progress($i/@images);
            Glib::MainContext::iteration(undef, 0);
            $images_store->iter_next($iter);
        }
        set_progress(0);
    }
}

sub index_log {
    my $line = shift;

    my $textview = $builder->get_object('text_indexlog');
    my $buffer = $textview->get_buffer();
    $buffer->insert($buffer->get_end_iter(), $line . "\n");
    while (Glib::MainContext::iteration(undef, 0)) {}
}

sub index_track {
    my $trackfile = shift;

    eval
    {
        my $mtime = (stat($trackfile))[9];
        if (my $itime = $trackdb->find_file($trackfile))
        {
            if ($itime > $mtime)
            {
                index_log("$trackfile already indexed");
                next;
            }
        }

        my $track = LocPic::Track->new($trackfile);
        unless (defined $track)
        {
            index_log("No tracks in $trackfile");
            next;
        }

        #print "track range: $track->{start_time} - $track->{end_time}\n";
        my $point = $track->get_point(0);
        #print "point: $point->{lat} $point->{lon}\n";

        $trackdb->add_track($track);
        index_log("$trackfile added to index");
    };
}

sub index_file {
    my $trackfile = $builder->get_object('file_trackfile')->get_filename();

    index_track($trackfile);
}

sub index_dir {
    my $trackdir = $builder->get_object('file_trackdir')->get_filename();

    opendir my $dir, $trackdir;
    while (my $file = readdir $dir)
    {
        next unless $file =~ /\.gpx$/i;
        my $path = "$trackdir/$file";
        index_track($path);
    }
    closedir $dir;    
}
