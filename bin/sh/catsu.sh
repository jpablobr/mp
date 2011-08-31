#!/usr/bin/perl
# ----------------------------------------------------------------------------
# Given a file as input, sorts and uniquifies contents and prints
# to standard out.
#
# Sept 14 2010
# ----------------------------------------------------------------------------
my @unique=();
while (<>) {
   chomp;
   next if not $_;
   my $next = $_;
   push @unique, $next if not grep {$_ eq $next} @unique;
}

print join("\n", sort @unique) . "\n" if @unique;
