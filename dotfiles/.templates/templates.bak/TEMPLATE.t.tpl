#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl (>>>FILE<<<)'

# Test file created outside of h2xs framework.
# Run this like so: `perl (>>>FILE<<<)'
#   (>>>USER_NAME<<<) <(>>>AUTHOR<<<)>     (>>>VC_DATE<<<)

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw( no_plan );
# BEGIN { use_ok( (>>>MODULE<<<) ); }
# BEGIN { plan tests => 1 };

use warnings;
use strict;
$|=1;
use Data::Dumper;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

(>>>POINT<<<)
