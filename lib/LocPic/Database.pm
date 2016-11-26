package LocPic::Database;

use strict;
use DBI;
use File::Path qw/make_path/;
use Path::Class;

my $dbpath = "$ENV{HOME}/.config/locpic/data.db";
my $dbhandle;

sub set_dbpath
{
    my ($pkg, $path) = @_;

    $dbpath = $path;

    $dbhandle = undef;
}

sub open_db
{
    unless (defined $dbhandle)
    {
        file($dbpath)->dir->mkpath;
        print "opening new database $dbpath\n";
        $dbhandle = DBI->connect("dbi:SQLite:dbname=$dbpath", '', '');
    }

    return $dbhandle;
}

1;
