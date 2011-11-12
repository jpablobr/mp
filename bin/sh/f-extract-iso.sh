#!/bin/bash

set -e

exe=$(basename $0)

die() {
    echo 1>&2 "$1"
    exit 1
}

usage() {

    cat 1>&2 <<-USAGE
$(tput setaf 2)
usage: $exe [ISO] [DIR]

Examples:
    # A simple, recursive, find and replace
    $exe path/to/file.iso where/to/mount/it

See also:
    mount(1)
$(tput op)
USAGE
    exit 1
}

[ "$#" -lt 2 ] &&  usage

from="$1" ; shift
to="$1" ; shift

echo "$(tput setaf 2) Mounting ISO $from in $to $(tput op)"
sudo mount -o loop $from $to
ls -la $to

exit 0
