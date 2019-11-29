#!/usr/bin/perl

my $VERSION=0.03;

my $leases_file = "/var/lib/dhcp/dhcpd.leases";

use strict;
use Date::Parse;

my $now = time;
my %seen;       # leases file has dupes (because logging failover stuff?). This hash will get rid of them.


open(L, $leases_file) or die "Cant open $leases_file : $!\n";
undef $/;
my @records = split /^lease\s+([\d\.]+)\s*\{/m, <L>;
shift @records; # remove stuff before first "lease" block

## process 2 array elements at a time: ip and data
foreach my $i (0 .. $#records) {
    next if $i % 2;
    my ($ip, $_) = @records[$i, $i+1];

    s/^\n+//;     # && warn "leading spaces removed\n";
    s/[\s\}]+$//; # && warn "trailing junk removed\n";

    my ($s) = /^\s* starts \s+ \d+ \s+ (.*?);/xm;
    my ($e) = /^\s* ends   \s+ \d+ \s+ (.*?);/xm;

    my $start = str2time($s);
    my $end   = str2time($e);

    my %h; # to hold values we want

    foreach my $rx ('binding', 'hardware', 'client-hostname') {
        my ($val) = /^\s*$rx.*?(\S+);/sm;
        $h{$rx} = $val;
    }

    my $formatted_output;

    if ($end && $end < $now) {
        $formatted_output =
            sprintf "%-15s : %-26s "              . "%19s "         . "%9s "     . "%24s    "              . "%24s\n",
                    $ip,     $h{'client-hostname'}, ""              , $h{binding}, "expired"               , scalar(localtime $end);
    }
    else {
        $formatted_output =
            sprintf "%-15s : %-26s "              . "%19s "         . "%9s "     . "%24s -- "              . "%24s\n",
                    $ip,     $h{'client-hostname'}, "($h{hardware})", $h{binding}, scalar(localtime $start), scalar(localtime $end);
    }

    next if $seen{$formatted_output};
    $seen{$formatted_output}++;
    print $formatted_output;
}

