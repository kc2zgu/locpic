package LocPic::Track;

use strict;

use Geo::Gpx;
use DateTime;
use LocPic::Point;
use File::Spec;
use Time::Series;

use base qw/Class::Accessor::Fast LocPic::Debug/;

LocPic::Track->mk_accessors(qw/start_time end_time file_name/);

sub new {
    my ($class, $gpxfile) = @_;

    open my $gpxfh, '<', $gpxfile;
    my $gpx = Geo::Gpx->new(input => $gpxfh, use_datetime => 1);

    my $self = { gpx => $gpx, points => [],
                 file_name => File::Spec->rel2abs($gpxfile) };
    bless $self, $class;

    return undef unless defined $gpx->tracks;

    $self->_load($gpx);

    return $self;
}

sub _load {
    my ($self, $gpx) = @_;

    $self->{ts} = Time::Series->new(axes => [qw/linear linear linear/], time_type => 'DateTime');

    for my $track(@{$gpx->tracks})
    {
        for my $seg(@{$track->{segments}})
        {
            for my $point(@{$seg->{points}})
            {
                push @{$self->{points}},
                  LocPic::Point->new(lat => $point->{lat},
                                     lon => $point->{lon},
                                     ele => $point->{ele},
                                     time => $point->{time});

                $self->{ts}->insert(@${point}{qw/time lat lon ele/});

                if (defined $self->{start_time})
                {
                    $self->{start_time} = $point->{time}
                      if $point->{time} < $self->{start_time};
                } else
                {
                    $self->{start_time} = $point->{time};
                }
                if (defined $self->{end_time})
                {
                    $self->{end_time} = $point->{time}
                      if $point->{time} > $self->{end_time};
                } else
                {
                    $self->{end_time} = $point->{time};
                }
            }
        }
    }
}

sub get_point {
    my ($self, $index) = @_;

    return $self->{points}->[$index];
}

sub points {
    my $self = shift;

    return scalar @{$self->{points}};
}

sub find_point {
    my ($self, $time) = @_;

    return $self->{points}->[0]
      if $time < $self->{start_time};
    return $self->{points}->[$#{$self->{points}}]
      if $time > $self->{end_time};

    if ($self->{ts})
    {
        my ($p, $s1, $s2) = $self->{ts}->lookup($time);
        if (defined $p)
        {
            if (defined $s1 && defined $s2)
            {
                my $timediff1 = $time->epoch - $s1->[0]->epoch;
                my $timediff2 = $s2->[0]->epoch - $time->epoch;
                $self->_debug(1 => "TS timediff: $timediff1 $timediff2");
            }
            return LocPic::Point->new(time => $time, lat => $p->[1], lon => $p->[2], ele => $p->[3]);
        }
    }
    else
    {
        my $i = 0;
        while (exists $self->{points}->[$i])
        {
            if ($self->{points}->[$i]->{time} > $time)
            {
                return @{$self->{points}}[$i-1, $i];
            }
            $i++;
        }
    }
    return undef;
}

sub find_points {
    my ($self, $time) = @_;

    return $self->{points}->[0]
      if $time < $self->{start_time};
    return $self->{points}->[$#{$self->{points}}]
      if $time > $self->{end_time};

    if ($self->{ts})
    {
        my @p = $self->{ts}->lookup($time);
        return map {LocPic::Point->new(time => $_->[0], lat => $_->[1], lon => $_->[2], ele => $_->[3])} @p;
    }
}

1;
