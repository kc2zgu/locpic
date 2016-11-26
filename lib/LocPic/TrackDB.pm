package LocPic::TrackDB;

use strict;
use DBI;
use LocPic::Database;
use DateTime;

sub new {
    my ($class, $dbfile) = @_;

    my $dbh = LocPic::Database->open_db;
    $dbh->do('CREATE TABLE IF NOT EXISTS tracks ( file UNIQUE, start, end, indexed )');
    $dbh->do('CREATE INDEX IF NOT EXISTS start_index ON tracks ( start )');
    $dbh->do('CREATE INDEX IF NOT EXISTS end_index ON tracks ( end )');

    my $self = {dbh => $dbh};
    bless $self, $class;
}

sub find_file {
    my ($self, $path) = @_;

    my $stmt = $self->{dbh}->prepare('SELECT * FROM tracks WHERE file = ?');
    if ($stmt->execute($path))
    {
        if (my $row = $stmt->fetchrow_hashref)
        {
            return $row->{indexed};
        }
    }
    return undef;
}

sub add_track {
    my ($self, $track) = @_;

    my $file = $track->file_name;
    my $start = $track->start_time;
    my $end = $track->end_time;
    my $now = time;
    print "adding $file [$start - $end] at $now\n";

    return $self->{dbh}->do('INSERT OR REPLACE INTO tracks ( file, start, end, indexed ) VALUES ( ?, ?, ?, ? )', undef,
                            $file, $start, $end, $now);
}

sub find_time {
    my ($self, $time) = @_;

    my $stmt = $self->{dbh}->prepare('SELECT file FROM tracks WHERE start <= ? AND end >= ?');
    if ($stmt->execute($time, $time))
    {
        my @tracks;
        while (my @row = $stmt->fetchrow_array)
        {
            push @tracks, \@row;
        }
        if (@tracks)
        {
            if (@tracks > 1)
            {
                print "multiple tracks\n";
            }
            return $tracks[0]->[0];
        }
        else
        {
            #print "no tracks for $time\n";
            my ($t1, $t2, $st, $et, $td1, $td2);
            my $etime = DateTime::Format::ISO8601->parse_datetime($time)->epoch;
            #print "time: $etime\n";
            $stmt = $self->{dbh}->prepare('SELECT file, start, end FROM tracks WHERE end <= ? ORDER BY end DESC LIMIT 1');
            if ($stmt->execute($time))
            {
                ($t1, $st, $et) = $stmt->fetchrow_array;
                #print "last before track: $t1 ($st-$et)\n";
                $td1 = $etime - DateTime::Format::ISO8601->parse_datetime($et)->epoch;
                #print "diff $td1 s\n";
            }
            $stmt = $self->{dbh}->prepare('SELECT file, start, end FROM tracks WHERE start >= ? ORDER BY start ASC LIMIT 1');
            if ($stmt->execute($time))
            {
                ($t2, $st, $et) = $stmt->fetchrow_array;
                #print "first after track: $t2 ($st-$et)\n";
                $td2 = DateTime::Format::ISO8601->parse_datetime($st)->epoch - $etime;
                #print "diff $td2 s\n";
            }
            my $maxdiff = 7200;
            if ($td1 > $maxdiff && $td2 > $maxdiff)
            {
                print "no track for $time\n";
                return undef;
            }
            my $rt = ($td1 < $td2) ? $t1 : $t2;
            print "closest track: $rt ($td1/$td2)\n";
            return $rt;
        }
    }
    return undef;
}


1;
