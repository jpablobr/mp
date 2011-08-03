#!/usr/bin/perl
# Examines a hex dump of a TCP/UDP packet and prints various info from the packet
use strict;
use warnings;
use Data::Dumper;

my $hex = '';
my $bin = '';
while (<>) {
    chomp;
    $hex .= $_;
}
$hex =~ s/[^0-9a-fA-F]//g;

for ( my $i = 0; $i < length ( $hex ); $i++ ) {
    $bin .= sprintf "%04b", hex substr ( $hex, $i, 1 );
}

sub bin2dec {
    return oct "0b" . shift;
}

sub bin2hex {
    my $hex = '';
    my $bin = shift;
    for ( my $i = 0; $i < length $bin; $i += 4 ) {
        $hex .= sprintf "%X", oct "0b" . substr ( $bin, $i, 4 );
    }
    return '0x' . $hex;
}

sub bin2ip {
    my $bin = shift;
    my @ip = ();
    for ( my $i = 0; $i < 4; $i++ ) {
        push @ip, bin2dec ( substr ( $bin, $i * 8, 8 ) );
    }
    return join ( '.', @ip );
}

sub bin2text {
    my $bin = shift;
    my $text = '';
    # Assume native 8-bit
    for ( my $i = 0; $i < length ( $bin ); $i += 8 ) {
        $text .= chr oct ( "0b" . substr ( $bin, $i, 8 ) );
    }
    return $text;
}

print "Hex read is: " .  bin2hex ( $bin ) . "\n";

my %packet = (
    eth => {
        dest => '',
        src => '',
        type => ''
    },
    ip => {
        ver => 0,
        hlen => 0,
        diffserv => {
            presc => 0,
            delay => 0,
            throu => 0,
            relia => 0,
            mcost => 0,
            nodef => 0,
        },
        tlen => 0,
        ident => 0,
        flags => {
            reserved => 0,
            dontfrag => 0,
            morefrag => 0,
        },
        foff => 0,
        ttl => 0,
        proto => 0,
        hcrc => '',
        src => '',
        dest => '',
        more => '',
    },
    ptype => '',
    udp => {
        src => 0,
        dest => 0,
        len => 0,
        crc => '',
    },
    tcp => {
        src => 0,
        dest => 0,
        seq => 0,
        ack => 0,
        off => 0,
        resv => 0,
        flags => {
            urg => 0,
            ack => 0,
            psh => 0,
            rst => 0,
            syn => 0,
            fin => 0,
        },
        wind => 0,
        crc => '',
        urgpnt => 0,
        opt => '',
    }
    data => '',
);

my $offset = 0;

#
# Ethernet
#
$bin =~ s/^(10101010)*10101011//; # Preamble
$packet{eth}{dest}  = bin2hex ( substr $bin, $offset, 6 * 8 );                       $offset += 6 * 8;
$packet{eth}{src}   = bin2hex ( substr $bin, $offset, 6 * 8 );                       $offset += 6 * 8;
$packet{eth}{type}  = bin2hex ( substr $bin, $offset, 2 * 8 );                       $offset += 2 * 8;

#
# IP
#
$packet{ip}{ver}   = bin2dec ( substr $bin, $offset, 1 * 4 );                        $offset += 1 * 4;
$packet{ip}{hlen}  = bin2dec ( substr $bin, $offset, 1 * 4 );                        $offset += 1 * 4;
    $packet{ip}{diffserv}{presc}  = bin2dec ( substr $bin, $offset, 3 );                         $offset += 3;
    $packet{ip}{diffserv}{delay}  = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{diffserv}{throu}  = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{diffserv}{relia}  = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{diffserv}{mcost}  = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{diffserv}{nodef}  = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
$packet{ip}{tlen}  = bin2dec ( substr $bin, $offset, 4 * 4 );                        $offset += 4 * 4;
$packet{ip}{ident} = bin2dec ( substr $bin, $offset, 4 * 4 );                        $offset += 4 * 4;
    $packet{ip}{flags}{reserved} = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{flags}{dontfrag} = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
    $packet{ip}{flags}{morefrag} = bin2dec ( substr $bin, $offset, 1 );                         $offset++;
$packet{ip}{foff}  = bin2dec ( substr $bin, $offset, 13 );                            $offset += 13;
$packet{ip}{ttl}   = bin2dec ( substr $bin, $offset, 2 * 4 );                         $offset += 2 * 4;
$packet{ip}{proto} = bin2dec ( substr $bin, $offset, 2 * 4 );                         $offset += 2 * 4;
$packet{ip}{hcrc}  = bin2hex ( substr $bin, $offset, 4 * 4 );           $offset += 4 * 4;
$packet{ip}{src}   = bin2ip ( substr $bin, $offset, 8 * 4 );           $offset += 8 * 4;
$packet{ip}{dest}  = bin2ip ( substr $bin, $offset, 8 * 4 );           $offset += 8 * 4;
if ( $packet{ip}{hlen} > 5 ) {
    $packet{ip}{more}  = bin2hex ( substr $bin, $offset, 32 * ( $packet{ip}{hlen} - 5 ) );           $offset += 32 * ( $packet{ip}{hlen} - 5 );
}

if ( $packet{ip}{proto} == 17 ) {
    #
    # UDP
    #
    $packet{udp}{src}   = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{udp}{dest}  = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{udp}{len}   = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{udp}{crc}   = bin2hex ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
} elsif ( $packet{ip}{proto} == 6 ) {
    #
    # TCP
    #
    $packet{tcp}{src}   = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{dest}  = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{seq}   = bin2dec ( substr $bin, $offset, 2 * 16 );                         $offset += 2 * 16;
    $packet{tcp}{ack}   = bin2dec ( substr $bin, $offset, 2 * 16 );                         $offset += 2 * 16;
    $packet{tcp}{off}   = bin2dec ( substr $bin, $offset, 1 * 4 );                          $offset += 1 * 4;
    $packet{tcp}{resv}  = bin2dec ( substr $bin, $offset, 1 * 6 );                          $offset += 1 * 6;
        $packet{tcp}{flags}{urg}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
        $packet{tcp}{flags}{ack}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
        $packet{tcp}{flags}{psh}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
        $packet{tcp}{flags}{rst}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
        $packet{tcp}{flags}{syn}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
        $packet{tcp}{flags}{fin}  = bin2dec ( substr $bin, $offset, 1 );                          $offset += 1;
    $packet{tcp}{wind}  = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{crc}   = bin2hex ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{urgpnt}= bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{wind}  = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;
    $packet{tcp}{wind}  = bin2dec ( substr $bin, $offset, 1 * 16 );                         $offset += 1 * 16;

    if ( $packet{tcp}{off} > 5 ) {
        $packet{tcp}{opt}  = bin2hex ( substr $bin, $offset, 32 * ( $packet{tcp}{off} - 5 ) );           $offset += 32 * ( $packet{tcp}{off} - 5 );
    }
}

$packet{data} = bin2text ( substr $bin, $offset );

print Dumper ( \%packet );
