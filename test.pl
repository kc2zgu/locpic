#!/usr/bin/perl

use strict;

use Test::Harness;
use Path::Tiny;
use FindBin;
use Config;

# get the base directory
my $rootdir = path($FindBin::Bin);
# add lib directory so tests can find local modules
my $locallib = $rootdir->child('lib');
$ENV{PERL5LIB} = join($Config{path_sep}, $locallib, $ENV{PERL5LIB});

# find the test-assets directory so tests can load input files
$ENV{LOCPIC_ASSETS} = $rootdir->child('test-assets');
# create a temp directory for tests to write files to (remove on exit)
my $temp = Path::Tiny->tempdir(TEMPLATE => 'locpic-test_XXXX', CLEANUP => 1);
$ENV{LOCPIC_TMP} = $temp;

# find all test scripts in t/
my $tdir = $rootdir->child('t');
my @tfiles = map {"$_"} $tdir->children(qr/\.t$/);

print "Test assets directory: $ENV{LOCPIC_ASSETS}\n";
print "Temporary directory: $ENV{LOCPIC_TMP}\n";
print "Running ", scalar @tfiles, " test files\n";

runtests(@tfiles);
