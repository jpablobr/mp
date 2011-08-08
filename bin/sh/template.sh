#!/bin/sh
# vim: set sw=4 ts=4 et:
help()
{
  cat <<HELP
Write usage and help text here
HELP
  exit 0
}

error()
{
    # print an error and exit
    echo "$1"
    exit 1
}

# The option parser, change it as needed
# In this example -f and -h take no arguments -l takes an argument
# after the l
while [ -n "$1" ]; do
case $1 in
    -h) help;shift 1;; # function help is called
    -f) opt_f=1;shift 1;; # variable opt_f is set
    -l) opt_l=$2;shift 2;; # -l takes an argument -> shift by 2
    --) shift;break;; # end of options
    -*) echo "error: no such option $1. -h for help";exit 1;;
    *)  break;;
esac
done

# The main program of you script comes after this line
error "ERROR: This is a generic script framework you must modify it first"
#
