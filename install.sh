#!/bin/sh

set -e

exe=$(basename $0)
mp=~/.mp
tmp_fl=./install~

_link_dotfiles() {
    echo -e "\nLinking MP dotfiles to ~\n"
    /bin/ls -1d ~/.mp/dotfiles/* | while read f; do
        [ ! -f ~/$(basename $f) -a ! -d ~/$(basename $f) ] && {
            ln -s $mp/$f ~ >> $tmp_fl
        }
    done
    cat $tmp_fl;exit
}

_clean_home() {
    echo -e "\nCleaning ~ dotfiles\n"
    /bin/ls -1d ~/.mp/dotfiles/* | while read f; do
        rm -vfr ~/$(basename $f) >> ./install~
    done
    cat $tmp_fl;exit
}

if [ "$1" = "c" ]; then
    _clean-home
elif [ "$1" = "l" ]; then
    _link-dotfiles
    _link-bin
else
    cat <<USAGE
    Usage: $exe [options]

    $exe c
    For removing ~ dotfiles.

    $exe l
    For linking MP bin and dotfiles to ~.

USAGE
    exit
fi
:
