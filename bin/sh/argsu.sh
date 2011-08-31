#!/usr/bin/perl
# ----------------------------------------------------------------------------
# Sorts and uniquifies parameters and prints to standard out.
#
# Sept 14 2010
# ----------------------------------------------------------------------------
my @unique=();
while (@ARGV) {
   chomp;
   my $next = shift @ARGV;
   push @unique, $next if not grep {$_ eq $next} @unique;
}

print join("\n", sort @unique) . "\n" if @unique;
