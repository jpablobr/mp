#!/usr/bin/env bash

set -e

: ${HOME=~}
exe=$(basename $0)
mp="$HOME/.mp"
bin_path='$HOME/bin'
mp_bin_path="$mp/bin"

_link-bin() {
    test ! -d	$bin && ln -s $mp_bin_path $bin
}

_link-dotfiles() {
    echo "Linking MP dotfiles to $HOME"
		for f in dotfiles/.?*; do
        test  $f != 'dotfiles/..'     &&
        test ! -f $HOME/`basename $f` &&
        test ! -d $HOME/`basename $f` &&
        ln -s $mp/$f $HOME            &&
        echo "Linking $mp/$f" $HOME/`basename $f`
    done
}

_clean-home() {
    echo "Cleaning $HOME dotfiles"
		for f in dotfiles/.?*; do
        test $f != 'dotfiles/..'   &&
        rm -fr $HOME/`basename $f` &&
        echo "Removed " $HOME/`basename $f`
    done
		rm -fr $bin_path
}

if [[ "$1" = "c" ]]; then
    _clean-home
elif [[ "$1" = "l" ]]; then
    _link-dotfiles
    _link-bin
else
cat 1>&2 <<-USAGE
    Usage: $exe [options]

    $exe c
    For removing $HOME dotfiles.

    $exe l
    For linking MP bin and dotfiles to $HOME.

USAGE
    exit 1
fi

exit 0