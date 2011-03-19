#!/bin/sh
# files.sh
# Files helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 18 Mar 2011
# Version: 0.1.0

# Open all files by given pattern.
function f_for_open {
    for file in "$1"; do
        open $file;
    done
}
function f_rename_ext {
    for file in *"$1"; do
        base=`basename $file "$1"`
        mv "$file" $base"$2"
    done
}

function rmf {
    for file in $*
    do
        __rm_single_file $file
    done
}

function __rm_single_file {
    if ! [ -d ~/.Trash/ ]
    then
        command /bin/mkdir ~/.Trash
    fi

    if ! [ $# -eq 1 ]
    then
        echo "__rm_single_file: 1 argument required but $# passed."
        exit
    fi

    if [ -e $1 ]
    then
        BASENAME=`basename $1`
        NAME=$BASENAME
        COUNT=0
        while [ -e ~/.Trash/$NAME ]
        do
            COUNT=$(($COUNT+1))
            NAME="$BASENAME.$COUNT"
        done

        command /bin/mv $1 ~/.Trash/$NAME
    else
        echo "No such file or directory: $file"
    fi
}

function touch {
  dir=`expr "$1" : '\(.*\/\)'`
  if [ $dir ]
    then
    mkdir -p $dir
  fi
  /usr/bin/touch $1
}

function f_prune_dirs {
# Remove empty directories under and including <path>s.
    find "$@" -type d -empty -depth | xargs rmdir
}

function remove_extension {
# Remove file extension to all files in current directory.
    for f in *; do
        base=`basename $f .$1`
        mv $f $base
    done
    ls -la .
}

function f_rename_ext {
# Rename file extentions"
    for f in *.$1; do
        base=`basename $f .$1`
        mv $f $base.$2
    done
    ls -la .
}

function switch {
# Switches two files contents
  mv $1 $1_orig &&
  mv $2 $1 &&
  mv $1_orig $2
}