#!/usr/bin/env perl
# Usage: scriptdoc [Options] File
# Reads the comments at the top of a script file for documentation

use strict;
use warnings;
use Getopt::Long;

Getopt::Long::Configure(
  'no_auto_abbrev',
  'no_ignore_case',
  'bundling',
  'pass_through'
);

my ($app_opts, @files, @needs);
GetOptions(
  'autodie'   => \$app_opts->{autodie},
  'file|f=s'  => \@files,
  'markdown'  => sub { $app_opts->{output} = 'markdown'; },
  'needs=s'   => \@needs,
);

@files = split(/,/,join(',',@files));
my %needmap = map { lc ($_) => undef } split(/,/,join(',',@needs));

my $meta = qr/^(\S+)\s*:(.*)$/;

for my $file (@files) {
  my $script = do { local $/; open my $fh, '<', "$file"; <$fh> };
  my %provides = %needmap;
  my $autodie = undef;
  my $buffer = "";

  for my $line (split (/^/, $script)) {
    $line =~ s/^#\s*// || last;
    ($line =~ s/^$/\n/ || $line =~ s/^!.*\n$// );
    $buffer .= $line;

    # match the key-value info from this line
    # multi-line (block) meta is not planned, yet.
    my ($tag, $content) = $line =~ /$meta/;
    if( $content ) {
      $provides{lc ($tag)} = 1 if exists $provides{lc ($tag)};
    }
  }

  # check`provides` for the metainfo we /need/
  for my $key (keys %provides) {
    warn "Missing the '$key' info from '$file'" unless $provides{$key};
    if ($app_opts->{autodie}) { $autodie = 1 unless $provides{$key}; }
  }

  die "Please report or fix the issues above." if $autodie;

  print render($buffer);
}

sub render {
  my $buffer = shift;
  return $buffer;
}

sub _markdown {
  my $buffer = shift;
  return $buffer;
}

sub name_val {
  my ($split) = @_;
}
