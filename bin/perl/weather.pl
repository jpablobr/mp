#!/usr/bin/env perl
# Author: Sartak 
# Repository: http://github.com/sartak/bindir
use strict;
use warnings;
use Weather::Google;

my $weather = Weather::Google->new('98125');

my $days = $weather->forecast_conditions;
for my $day (@$days) {
    print "[$day->{day_of_week}] $day->{low}-$day->{high}: $day->{condition}\n";
}

