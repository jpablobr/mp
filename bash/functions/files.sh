#!/usr/bin/env bash
# files.sh
# Files helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

# aliases
alias f-list_biggest_in_tree='find . -ls | sort -n -k 7 | tail -5'
alias f-broken_links='find . -type l | (while read FN ; do test -e "$FN" || ls -ld "$FN"; done)'
alias f-symlinks='find . -type l'
alias f-remove_symlinks='for f in $(find . -type l); do rm $f; done'

# moving in dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

chmod-files(){
    find . -type f -exec chmod -v "$1" {} \;
}

f-for-open() {
# Open all files by given pattern.
    for file in "$1"; do
        open $file;
    done
}

f-prune-dirs() {
# Remove empty directories under and including <path>s.
    find "$@" -type d -empty -depth | xargs rmdir
}

f-remove-extension() {
# Remove file extension to all files in current directory.
    for f in *; do
        local base=`basename $f .$1`
        mv $f $base
    done
}

f-rename-ext() {
    for f in *.$1; do
        local base=`basename $f .$1`
        mv $f $base.$2
    done
}

f-switch-files-contents() {
  mv $1 $1_orig &&
  mv $2 $1 &&
  mv $1_orig $2
}

f-m() {
  local file=.
  local cd_to=.

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


duh() { # disk usage for humans
  test $# -eq 0 && set -- *
  du -sch "$@" | sort -h
}

ac() { # compress a file or folder
    case "$1" in
       tar.bz2|.tar.bz2) tar cvjf "${2%%/}.tar.bz2" "${2%%/}/" ;;
       tbz2|.tbz2)       tar cvjf "${2%%/}.tbz2" "${2%%/}/"    ;;
       tbz|.tbz)         tar cvjf "${2%%/}.tbz" "${2%%/}/"     ;;
       tar.xz)           tar cvJf "${2%%/}.tar.gz" "${2%%/}/"  ;;
       tar.gz|.tar.gz)   tar cvzf "${2%%/}.tar.gz" "${2%%/}/"  ;;
       tgz|.tgz)         tar cvjf "${2%%/}.tgz" "${2%%/}/"     ;;
       tar|.tar)         tar cvf  "${2%%/}.tar" "${2%%/}/"     ;;
       rar|.rar)         rar a    "${2}.rar" "$2"              ;;
       zip|.zip)         zip -9   "${2}.zip" "$2"              ;;
       7z|.7z)           7z a     "${2}.7z" "$2"               ;;
       lzo|.lzo)         lzop -v  "$2"                         ;;
       gz|.gz)           gzip -v  "$2"                         ;;
       bz2|.bz2)         bzip2 -v "$2"                         ;;
       xz|.xz)           xz -v    "$2"                         ;;
       lzma|.lzma)       lzma -v  "$2"                         ;;
           *)           echo "ac(): compress a file or directory."
       echo "Usage:   ac <archive type> <filename>"
       echo "Example: ac tar.bz2 PKGBUILD"
       echo "Please specify archive type and source."
       echo "Valid archive types are:"
       echo "tar.bz2, tar.gz, tar.gz, tar, bz2, gz, tbz2, tbz,"
       echo "tgz, lzo, rar, zip, 7z, xz and lzma." ;;
    esac
}

ad() { # decompress archive (to directory $2 if wished for and possible)
   if [ -f "$1" ] ; then
       case "$1" in
       *.tar.bz2|*.tgz|*.tbz2|*.tbz) mkdir -v "$2" 2>/dev/null ; tar xvjf "$1" -C "$2" ;;
       *.tar.gz)                     mkdir -v "$2" 2>/dev/null ; tar xvzf "$1" -C "$2" ;;
       *.tar.xz)                     mkdir -v "$2" 2>/dev/null ; tar xvJf "$1"         ;;
       *.tar)                        mkdir -v "$2" 2>/dev/null ; tar xvf  "$1" -C "$2" ;;
       *.rar)                        mkdir -v "$2" 2>/dev/null ; 7z x     "$1"    "$2" ;;
       *.zip)                        mkdir -v "$2" 2>/dev/null ; unzip    "$1" -d "$2" ;;
       *.7z)                         mkdir -v "$2" 2>/dev/null ; 7z x     "$1" -o "$2" ;;
       *.lzo)                        mkdir -v "$2" 2>/dev/null ; lzop -d  "$1" -p "$2" ;;
       *.gz)                         gunzip "$1"                                       ;;
       *.bz2)                        bunzip2 "$1"                                      ;;
       *.Z)                          uncompress "$1"                                   ;;
       *.xz|*.txz|*.lzma|*.tlz)      xz -d "$1"                                        ;;
       *)
       esac
   else
              echo "Sorry, '$2' could not be decompressed."
              echo "Usage: ad <archive> <destination>"
              echo "Example: ad PKGBUILD.tar.bz2 ."
              echo "Valid archive types are:"
              echo "tar.bz2, tar.gz, tar.xz, tar, bz2,"
              echo "gz, tbz2, tbz, tgz, lzo,"
              echo "rar, zip, 7z, xz and lzma"
   fi
}

al() { # list content of archive but don't unpack
    if [ -f "$1" ]; then
         case "$1" in
       *.tar.bz2|*.tbz2|*.tbz)  tar -jtf "$1" ;;
       *.tar.gz)                tar -ztf "$1" ;;
       *.tar|*.tgz|*.tar.xz)    tar -tf "$1"  ;;
       *.gz)                    gzip -l "$1"  ;;
       *.rar)                   rar vb "$1"   ;;
       *.zip)                   unzip -l "$1" ;;
       *.7z)                    7z l "$1"     ;;
       *.lzo)                   lzop -l "$1"  ;;
       *.xz|*.txz|*.lzma|*.tlz) xz -l "$1"    ;;
         esac
    else
     echo "Sorry, '$1' is not a valid archive."
     echo "Valid archive types are:"
     echo "tar.bz2, tar.gz, tar.xz, tar, gz,"
     echo "tbz2, tbz, tgz, lzo, rar"
     echo "zip, 7z, xz and lzma"
    fi
}

full_path() {
    echo "$(cd $(dirname "$1"); pwd -P)/$(basename "$1")"
}


##############################################################################->
# - Encript
f-encrypt-compress () {
    [ "$#" -lt 1 ] &&
    echo "Must provide a file name to tar.gz and encrypt." &&
    exit 1
    tar -vcj "$1" |
    gpg --encrypt \
        --recipient $(whoami) > "$1".tar.gz
    exit 0
 }

f-decrypt-decompress () {
    [ "$#" -lt 1 ] &&
    echo "Must provide a file name to un-tar.gz and de-crypt." &&
    echo "Provide the filebase name without the tar.gz extension" &&
    exit 1
    gpg --verbose \
        --output "$1" \
        --decrypt "$1".tar.gz &&
    tar -xvvf "$1"
    exit 0
}

find_larger() { find . -type f -size +${1}c ; }