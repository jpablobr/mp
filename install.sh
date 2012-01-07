#!/bin/sh

set -e

exe=$(basename $0)
mp=~/.mp

_link-dotfiles() {
    echo "Linking MP dotfiles to ~"
		for f in dotfiles/.?*; do
        test  $f != 'dotfiles/..'     &&
        test ! -f ~/$(basename $f) &&
        test ! -d ~/$(basename $f) &&
        ln -s $mp/$f ~            &&
        echo "Linking $mp/$f" ~/$(basename $f)
    done
}

_clean-home() {
    echo "Cleaning ~ dotfiles"
		for f in dotfiles/.?*; do
        test $f != 'dotfiles/..'   &&
        rm -fr ~/$(basename $f) &&
        echo "Removed " ~/$(basename $f)
    done
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
