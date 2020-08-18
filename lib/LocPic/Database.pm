package LocPic::Database;

use strict;
use DBI;
use Path::Tiny;
use File::HomeDir;

my $dbpath = path(File::HomeDir->my_data)->child('locpic', 'data.db');
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
        $dbpath->parent->mkpath;
        print "opening new database $dbpath\n";
        $dbhandle = DBI->connect("dbi:SQLite:dbname=$dbpath", '', '');
    }

    return $dbhandle;
}

1;
