#!/usr/bin/perl

use strict;

use Test::Harness;
use Path::Tiny;
use FindBin;

my $rootdir = path($FindBin::Bin);
my $locallib = $rootdir->child('lib');
if (defined $ENV{PERL5LIB})
{
    $ENV{PERL5LIB} = "$locallib:$ENV{PERl5LIB}";
} else
{
    $ENV{PERL5LIB} = $locallib;
}

$ENV{LOCPIC_ASSETS} = $rootdir->child('test-assets');

my $tdir = $rootdir->child('t');
my @tfiles = map {"$_"} $tdir->children(qr/\.t$/);
print "assets dir: $ENV{LOCPIC_ASSETS}\n";
print "tests: @tfiles\n";
runtests(@tfiles);
