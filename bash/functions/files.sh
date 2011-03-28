#!/bin/sh
# files.sh
# Files helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 18 Mar 2011
# Version: 0.1.0

# Open all files by given pattern.
f-for-open() {
    for file in "$1"; do
        open $file;
    done
}
f-rename-ext() {
    for file in *"$1"; do
        base=`basename $file "$1"`
        mv "$file" $base"$2"
    done
}

f-rmf() {
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

touch() {
  dir=`expr "$1" : '\(.*\/\)'`
  if [ $dir ]
    then
    mkdir -p $dir
  fi
  /usr/bin/touch $1
}

f-prune-dirs() {
# Remove empty directories under and including <path>s.
    find "$@" -type d -empty -depth | xargs rmdir
}

f-remove-extension() {
# Remove file extension to all files in current directory.
    for f in *; do
        base=`basename $f .$1`
        mv $f $base
    done
    ls -la .
}

f-rename-ext() {
# Rename file extentions"
    for f in *.$1; do
        base=`basename $f .$1`
        mv $f $base.$2
    done
    ls -la .
}

f-switch() {
# Switches two files contents
  mv $1 $1_orig &&
  mv $2 $1 &&
  mv $1_orig $2
}
function f() { find * -name $1; }

f-m() {
  file=.
  cd_to=.

  if [ -n "$*" ]; then
    if [ -d "$1" ]; then
      cd_to=$1
      file=.
    else
      file=$*
    fi
  fi

  eval "cd $cd_to && $VISUAL $file"
}

##############################################################################->
# - Compression
f-extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2) tar xvjf $1   ;;
      *.tar.gz)  tar xvzf $1   ;;
      *.bz2)     bunzip2 $1    ;;
      *.rar)     unrar x $1    ;;
      *.gz)      gunzip $1     ;;
      *.tar)     tar xvf $1    ;;
      *.tbz2)    tar xvjf $1   ;;
      *.tgz)     tar xvzf $1   ;;
      *.zip)     unzip $1      ;;
      *.Z)       uncompress $1 ;;
      *.7z)      7z x $1       ;;
      *)         echo "'$1' cannot be extracted via >extract<" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Install a .tar.gz archive in current directory
tardir() {
    if [ $# != 0 ]; then tar zxvf $1; fi
}

# List the contents of a .zip archive
cz() {
    if [ $# != 0 ]; then unzip -l $*; fi
}

# List the contents of a .tar.gz archive
ctgz() {
    for file in $* ; do
        tar ztf ${file}
    done
}

# Create a .tgz archive a la zip.
tgz() {
    if [ $# != 0 ]; then
        name=$1.tar; shift; tar -rvf ${name} $* ; gzip -9 ${name}
    fi
}

function zipr() {
    zip -r $1.zip $1
}
