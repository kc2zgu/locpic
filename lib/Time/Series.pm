package Time::Series;

use 5.022000;
use strict;
use warnings;

use List::BinarySearch qw/binsearch_pos/;

use base qw/LocPic::Debug/;

our $VERSION = '0.01';


sub new {
    my $class = shift;

    my %opts = @_;

    my $self = {axes => $opts{axes}, time_type => $opts{time_type} // 'epoch', samples => []};

    bless $self, $class;
}

sub insert {
    my $self = shift;

    return $self->insert([@_])
      unless ref $_[0] eq 'ARRAY';

    my $inserted = 0;
    for my $sample (@_)
    {
        my $count = $self->samples;
        if (@$sample <= $self->{axes} && @$sample >= 1)
        {
            if ($count == 0 || $sample->[0] > $self->{samples}->[$count-1]->[0])
            {
                push @{$self->{samples}}, $sample;
                $inserted++;
            }
            elsif ($sample->[0] < $self->{samples}->[0]->[0])
            {
                unshift @{$self->{samples}}, $sample;
                $inserted++;
            }
            elsif ($sample->[0] == $self->{samples}->[$count-1]->[0])
            {
                warn "replacing last sample $sample->[0]";
                $self->{samples}->[$count-1] = $sample;
            }
            else
            {
                warn "unsorted insert $sample->[0]";
                my @samples = @{$self->{samples}};
                push @samples, $sample;
                $self->{samples} = [sort {$a->[0] <=> $b->[0]} @samples];
                $inserted++;
            }
        }
    }
    return $inserted;
}

sub samples {
    my $self = shift;

    if (wantarray)
    {
        return @{$self->{samples}};
    }
    else
    {
        return scalar @{$self->{samples}};
    }
}

sub get {
    my ($self, $index) = @_;

    if ($index >= 0 && $index < @{$self->{samples}})
    {
        return $self->{samples}->[$index];
    }

    return undef;
}

sub _compare_time {
    my ($self, $key1, $key2) = @_;

    if ($self->{time_type})
    {
        if ($self->{time_type} eq 'numeric')
        {}
    }
    else
    {
        return $key1 <=> $key2;
    }
}

sub lookup {
    my ($self, $key) = @_;

    if ($key < $self->{samples}->[0]->[0])
    {
        return $self->{samples}->[0];
    }
    elsif ($key > $self->{samples}->[$#{$self->{samples}}]->[0])
    {
        return $self->{samples}->[$#{$self->{samples}}];
    }
    else
    {
        my $index = binsearch_pos {$a->[0] <=> $b->[0]}
          [$key], @{$self->{samples}};

        if ($self->{samples}->[$index]->[0] == $key)
        {
            return $self->{samples}->[$index];
        }
        else
        {
            my $s1 = $self->{samples}->[$index-1];
            my $s2 = $self->{samples}->[$index];
            my @out = ($key);
            for my $axis(0..$#{$self->{axes}})
            {
                if ($self->{axes}->[$axis] eq 'linear')
                {
                    my $pos;
                    if ($self->{time_type} eq 'DateTime')
                    {
                        my $d1 = $s2->[0]->epoch - $s1->[0]->epoch;
                        my $d2 = $key->epoch - $s1->[0]->epoch;
                        $pos = $d2 / $d1;
                        $self->_debug(1 => "$axis s1: $s1->[0] s2: $s2->[0] key: $key d1: $d1 d2: $d2 p: $pos");
                    } else
                    {
                        $pos = ($key - $s1->[0]) / ($s2->[0] - $s1->[0]);
                    }
                    push @out,
                      $s1->[$axis+1] + ($s2->[$axis+1] - $s1->[$axis+1]) * $pos;
                    #print "ret $out[$#out]\n";
                }
            }
            if (wantarray)
            {
                print "TS: array return\n";
                return (\@out, $s1, $s2);
            }
            else
            {
                print "TS: scalar return\n";
                return \@out;
            }
        }
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Time::Series - Store and access time series data with optional interpolation

=head1 SYNOPSIS

  use Time::Series;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Time::Series, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>steve@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
