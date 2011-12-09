#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Net::SMTP;

Getopt::Long::Configure(
  'no_auto_abbrev',
  'no_ignore_case',
  'bundling',
  'pass_through'
);

my $opts = {};
GetOptions(
  'from=s'       => \$opts->{from},
  'host|H=s'     => \$opts->{host},
  'port|p=i'     => \$opts->{port},
  'to=s'         => \$opts->{to},
) or pod2usage(2);

for (@ARGV) {
  if (/^verify$/) { verify_address($opts->{host}, $opts->{to}) }
  if (/^testmail$/){ send_test_mail($opts->{host}, $opts->{to}, $opts->{from}) }
}

sub verify_address {
  my ($host, $to) = @_;

  my $smtp = Net::SMTP->new($host,
    Hello => '',
    Debug => 1,
  ) 
  ->verify($to);

  exit 0;
}

sub send_test_mail {
  my ($host, $to, $from) = @_;

  my @data = [
    "to: $to\n",
    "from: $from\n",
    "subject: Routing Test\n",
    "\n",
    "If you are reading this message, it means that routing to $to is functioning.\n",
    "\n",
    "Cheers!\n",
    "\n"
  ];

  my $smtp = Net::SMTP->new($host,
    Hello => '',
    Debug => 1,
  );
  
  $smtp->verify($to);
  $smtp->mail($from);
  $smtp->to($to);
  $smtp->data(@data);
  $smtp->quit();

  exit 0;
}
