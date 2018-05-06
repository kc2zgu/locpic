package LocPic::Image;

use strict;

use Image::ExifTool;
use Image::ExifTool::Location;
use DateTime;
use File::Basename;

use base qw/LocPic::Debug/;

sub new {
    my ($class, $file) = @_;

    my $self = { file => $file, filebase => basename($file), exif => Image::ExifTool->new(), metadirty => 0 };
    $self->{exif}->ExtractInfo($file, {Group0 => ['EXIF', 'XMP', 'File']});
    my $type = $self->{exif}->GetValue('MIMEType');

    if ($type =~ /^image/)
    {
        bless $self, $class;
        return $self;
    }
    else
    {
        return undef;
    }
}

sub DESTROY {
    my $self = shift;

    if ($self->{metadirty})
    {
        warn "Image $self->{filebase}: object destroyed with unsaved metadata\n";
    }
}

sub get_time {
    my $self = shift;

    my $exif_dto = $self->{exif}->GetValue('DateTimeOriginal', 'ValueConv');
    my ($year, $month, $day, $hour, $min, $sec) =
      $exif_dto =~ /(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/;

    my $dt = DateTime->new(year => $year, month => $month, day => $day,
                           hour => $hour, minute => $min, second => $sec);

    return $dt;
}

sub get_camera {
    my $self = shift;

    my $make = $self->{exif}->GetValue('Make');
    my $model = $self->{exif}->GetValue('Model');
    my $serial = $self->{exif}->GetValue('SerialNumber');

    if (wantarray)
    {
        return ($make, $model, $serial);
    } else
    {
        $model =~ s/^$make\s+?//;
        my $str;
        if (length $make && length $model)
        {
            $str = "$make $model";
        }
        elsif (length $model)
        {
            $str = $model;
        }
        else
        {
            $str = 'Unknown';
        }
        if (length $serial)
        {
            $str .= ":$serial";
        }
        return $str;
    }
}

sub get_location {
    my $self = shift;

    if ($self->{exif}->HasLocation())
    {
        my ($lat, $lon) = $self->{exif}->GetLocation();
        my $point = LocPic::Point->new(lat => $lat, lon => $lon);
        if ($self->{exif}->HasElevation())
        {
            $point->ele($self->{exif}->GetElevation());
        }
        return $point;
    }
    return undef;
}

sub set_location {
    my ($self, $point) = @_;

    $self->{exif}->SetLocation($point->lat, $point->lon);
    $self->{exif}->SetElevation($point->ele) if defined $point->ele;

    $self->{metadirty} = 1;
}


sub write_meta {
    my ($self, $backup) = @_;

    if (defined $backup)
    {
        my $bakfile = "$self->{file}.bak";
        $self->_debug(1 => "Writing metadata, original saved to $bakfile");
        rename $self->{file}, $bakfile;
        if ($self->{exif}->WriteInfo($bakfile, $self->{file}) == 1)
        {
            $self->{metadirty} = 0;
        }
        else
        {
            warn "Error saving metadata for $self->{filebase}";
        }
    } else
    {
        $self->_debug(1 => "Writing metadata to $self->{file}");
        if ($self->{exif}->WriteInfo($self->{file}) == 1)
        {
            $self->{metadirty} = 0;
        }
        else
        {
            warn "Error saving metadata for $self->{filebase}";
        }
    }
}

1;
