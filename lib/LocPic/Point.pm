package LocPic::Point;

use strict;

use base qw/Class::Accessor::Fast/;

LocPic::Point->mk_accessors(qw/lat lon ele time/);

sub new {
    my $class = shift;

    my $self = {};
    if (@_)
    {
        %$self = @_;
    }
    bless $self, $class;
}

1;
