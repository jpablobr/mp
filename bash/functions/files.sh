#!/usr/bin/env bash
# files.sh
# Files helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

# aliases
alias f-list_biggest_in_tree='find . -ls | sort -n -k 7 | tail -5'
alias f-broken_links='find . -type l | (while read FN ; do test -e "$FN" || ls -ld "$FN"; done)'
alias f-symlinks='find . -type l'
alias f-remove_symlinks='for f in $(find . -type l); do rm $f; done'
alias f=find

f-for-open() {
# Open all files by given pattern.
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
}

f-rename-ext() {
    for f in *.$1; do
        base=`basename $f .$1`
        mv $f $base.$2
    done
}

f-switch-files-contents() {
  mv $1 $1_orig &&
  mv $2 $1 &&
  mv $1_orig $2
}

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
f-compress-zipr() { zip -r $1.zip $1; }
f-compress-tardir() { if [ $# != 0 ]; then tar zxvf "$1"; fi }
f-compress-bz2() { if [ $# != 0 ]; then tar jcvf ./"$1".tar.bz2 "$1"; fi }
f-compress-tgz() { if [ $# != 0 ]; then name=$1.tar; shift; tar -rvf ${name} $* ; gzip -9 ${name}; fi }
f-find-and-rm() { find . -name "$1" -exec rm {} \;;}
f-list-content-zipped() { if [ $# != 0 ]; then unzip -l $*; fi }
f-list-content-targz() { for file in $* ; do  tar ztf ${file}; done }

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

##############################################################################->
# - Encript
f-encript-compress () { tar -cj "$1" | gpg --encrypt -r "$2" > "$1".tar.gz; }
f-encript-decompress () { gpg --decrypt -output "$1" "$1".tar.gz && tar -xvvf "$1"; }