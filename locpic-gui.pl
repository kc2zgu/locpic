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

Gtk3::main();

my ($image, $itime, $izone);

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
    my $offset_s = $offset->hours * 3600 + $offset->minutes * 60 + $offset->seconds;
    $builder->get_object('label_time_offset')->set_label($offset_s);
}
