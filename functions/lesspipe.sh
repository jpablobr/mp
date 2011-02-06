#!/bin/sh
# This is a preprocessor for 'less'.  It is used when this environment
# variable is set:   LESSOPEN="|lesspipe.sh %s"

lesspipe () {
  case "$1" in
  *.tar) tar tf $1 2>/dev/null ;; # View contents of .tar and .tgz files
  *.tgz|*.tar.gz|*.tar.Z|*.tar.z) tar ztf $1 2>/dev/null ;;
  *.Z|*.z|*.gz) gzip -dc $1  2>/dev/null ;; # View compressed files correctly
  *.tar.bz2) bzip2 -dc $1 | tar tf - ;;
  *.bz2) bzip2 -dc $1  2>/dev/null ;;
  *.zip) unzip -l $1 2>/dev/null ;; # View archives
  *.arj) unarj -l $1 2>/dev/null ;;
  *.rpm) rpm -qpil $1 2>/dev/null ;;
  *.cpio) cpio --list -F $1 2>/dev/null ;;
  *.1|*.2|*.3|*.4|*.5|*.6|*.7|*.8|*.9|*.n|*.l|*.man)
    file $1 | grep roff > /dev/null
    if [ $? = 0 ]; then
      groff -Tascii -mandoc $1
    fi ;;
  *) file $1 | grep "te[sx]t" > /dev/null ;
    if [ $? = 1 ] ; then # it's not some kind of text
      strings $1
    fi ;;
  esac
}

# treat link targets, not links themselves
file $1 | grep symbolic > /dev/null
if [ $? = 0 ]; then
  TARGET=$(file $1 | awk '{print $NF}')
  lesspipe $TARGET
else
  lesspipe $1
fi