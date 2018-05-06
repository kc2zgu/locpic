package LocPic::Debug;

use strict;

my $debug_level = 0;

sub _debug {
    my ($self, $level, $message) = @_;

    if ($debug_level >= $level)
    {
        print $message, "\n";
    }
}

sub set_level {
    my ($class, $level) = @_;

    $debug_level = $level;
}

1;
