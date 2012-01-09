#!/bin/sh

set -e

exe=$(basename $0)
mp=~/.mp
tmp_fl=./install~
tmp_dir=/tmp/mp-dotfiles

_link_dotfiles() {
    echo -e "\nLinking MP dotfiles to ~\n"
    /bin/ls -1d  $mp/dotfiles/* | while read f; do
        [ ! -f ~/$(basename $f) -a ! -d ~/$(basename $f) ] && {
            ln -s $mp/dotfiles/$f ~ >> $tmp_fl 2>&1
        }
    done
    cat $tmp_fl;exit
}

_clean_home() {
    echo -e "\nCleaning ~ dotfiles\n"
		[ -d $tmp_dir ] && mktmp $tmp_dir
    /bin/ls -1d $mp/dotfiles/* | while read f; do
        mv -v ~/$(basename $f) $tmp_dir >> $tmp_fl 2>&1
    done
    cat $tmp_fl;exit
}

if [ "$1" = "c" ]; then
    _clean_home
elif [ "$1" = "l" ]; then
    _link_dotfiles
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
