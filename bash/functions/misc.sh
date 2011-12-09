#!/usr/bin/env bash
# misc.sh
# General helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

alias pygrep="grep --include='*.py' $*"
alias rbgrep="grep --include='*.rb' $*"
alias ducks="du -cksh * |sort -rn |head -10" # print top 10 largest files in pwd
alias psm="echo '%CPU %MEM   PID COMMAND' && ps hgaxo %cpu,%mem,pid,comm | sort -nrk1 | head -n 10 | sed -e 's/-bin//' | sed -e 's/-media-play//'"
alias chmodfx="find . -type f -print0 | xargs -0 chmod +x"
alias scan="sudo iwlist wlan0 scan | grep ESSID"
alias scanfull="sudo iwlist wlan0 scan"
alias grep="grep --color=auto"
alias lla="ls -la"
alias la="ls -a"
alias llatr="ls -latr"
alias ps.cpu="ps ahuwx | sort -nr -k 3 | head -n10"
alias ps.mem="ps ahuwx | sort -nr -k 4 | head -n10"
# multiple-spaces > single-space
alias sed.ws="sed -ne 's/  */ /gp'"
# tabs > new-line
alias sed.tn="sed -ne 's/\t/\n/gp'"
alias termcast="telnet termcast.org"
alias term.reset="echo c; stty echo"
alias when="when --calendar_today_style='underlined,fgyellow,bgblack' --items_today_style='bold,fgred,bgblack'"

alias xargs0="xargs -0"

mkcd () {
  mkdir -p $1 &&\
  cd $1
}

cdf() {
    cd *$1*/
}

free () {
  case $1 in
    mem)
      perl -ane 'BEGIN{$mem;} if (/^(MemFree:|Buffers:|Cached:).*?(\d+)/) {$mem += $2;} END{print $mem;}' /proc/meminfo
      ;;
    mem_total)
      grep MemTotal /proc/meminfo | sed 's/[^0-9]//g'
      ;;
    swap)
      grep SwapFree /proc/meminfo | sed 's/[^0-9]//g'
      ;;
    swap_total)
      grep SwapTotal /proc/meminfo | sed 's/[^0-9]//g'
      ;;
    *)
      free -m
      ;;
  esac
}

##############################################################################->
# - Grep
g-.() { grep -nH -e "$@";}
f() { find . -type f -print0 | xargs -0 -e grep -nH -e "$1"; }
gr-fp() { find "$1" -type f -print0 | xargs -0 -e grep -nH -e "$2"; }
gr-linux-yac() { grep -nH -e "$@" ~/org/yacs/linux.org; }
gr-less() { egrep --color=yes "$@" | less -R; }

##############################################################################->
# - Databases
loaddb() {
    mysql -u root $1 < $1.sql
}

dumpdb() {
    mysqldump -u root --add-drop-table --no-create-db $1 > $1.sql
}

dumpschema() {
    mysqldump -u root --add-drop-table --no-create-db --no-data $1 > schema.s
}

GET() {
  curl -i -X GET -H "X-Requested-With: XMLHttpRequest" $*
}

POST() {
  curl -i -X POST -H "X-Requested-With: XMLHttpRequest" $*
  #-d "key=val"
}

PUT() {
  curl -i -X PUT -H "X-Requested-With: XMLHttpRequest" $*
}

DELETE() {
  curl -i -X DELETE -H "X-Requested-With: XMLHttpRequest" $*
}

json() {
  tmpfile=`mktemp -t json`
  curl -s $* | python -mjson.tool > $tmpfile
  cat $tmpfile
  cat $tmpfile | pbcopy
  rm $tmpfile
}

xml() {
  tmpfile=`mktemp -t xml`
  curl -s $* | xmllint —format - > $tmpfile
  cat $tmpfile
  cat $tmpfile | pbcopy
  rm $tmpfile
}

ansi2html() {
    cat "$1" | ansi2html.sh "$1" > "$1".html
}
##############################################################################->
# - General

knpviewer() {
    for name in $(ps ux | awk '/npviewer.bin/ && !/awk/ {print $2}'); do
        kill "$name"
    done
}

last_modified(){
    ls -t $* 2> /dev/null | head -n 1
}

dbox-bitch() {
    sudo pkill dropboxd &&
    sudo sysctl fs.inotify.max_user_watches=1000000 &&
    dropboxd
}

moduse() {
    pkg="$1"
    shift
    ack -L "use $pkg" `ack -l "$pkg" $*`
}

psg() { ps aux | head -1 | grep -v Broken ; ps aux | grep $* | grep -v grep; }
pod() { pod2man "$*" | nroff -man | less; }
localtime () { perl -le 'for (@ARGV) { print scalar localtime($_) }' $*; }
iplist() { ifconfig | perl -nle '/dr:(\S+)/ && print $1'; }

mkcd() {
  mkdir -p "$*"
  cd "$*"
}

duh() { # disk usage for humans
  test $# -eq 0 && set -- *
  du -sch "$@" | sort -h
}

ac() { # compress a file or folder
    case "$1" in
           tar.bz2|.tar.bz2) tar cvjf "${2%%/}.tar.bz2" "${2%%/}/"  ;;
       tbz2|.tbz2)       tar cvjf "${2%%/}.tbz2" "${2%%/}/"     ;;
       tbz|.tbz)         tar cvjf "${2%%/}.tbz" "${2%%/}/"      ;;
       tar.xz)         tar cvJf "${2%%/}.tar.gz" "${2%%/}/"      ;;
       tar.gz|.tar.gz)   tar cvzf "${2%%/}.tar.gz" "${2%%/}/"   ;;
       tgz|.tgz)         tar cvjf "${2%%/}.tgz" "${2%%/}/"      ;;
       tar|.tar)         tar cvf  "${2%%/}.tar" "${2%%/}/"        ;;
           rar|.rar)         rar a "${2}.rar" "$2"            ;;
       zip|.zip)         zip -9 "${2}.zip" "$2"            ;;
       7z|.7z)         7z a "${2}.7z" "$2"            ;;
       lzo|.lzo)         lzop -v "$2"                ;;
       gz|.gz)         gzip -v "$2"                ;;
       bz2|.bz2)         bzip2 -v "$2"                ;;
       xz|.xz)         xz -v "$2"                    ;;
       lzma|.lzma)         lzma -v "$2"                ;;
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
       *.tar.gz)             mkdir -v "$2" 2>/dev/null ; tar xvzf "$1" -C "$2" ;;
       *.tar.xz)             mkdir -v "$2" 2>/dev/null ; tar xvJf "$1" ;;
       *.tar)             mkdir -v "$2" 2>/dev/null ; tar xvf "$1"  -C "$2" ;;
       *.rar)             mkdir -v "$2" 2>/dev/null ; 7z x   "$1"     "$2" ;;
       *.zip)             mkdir -v "$2" 2>/dev/null ; unzip   "$1"  -d "$2" ;;
       *.7z)             mkdir -v "$2" 2>/dev/null ; 7z x    "$1"   -o"$2" ;;
       *.lzo)             mkdir -v "$2" 2>/dev/null ; lzop -d "$1"   -p"$2" ;;
       *.gz)             gunzip "$1"                       ;;
       *.bz2)             bunzip2 "$1"                       ;;
       *.Z)                 uncompress "$1"                       ;;
       *.xz|*.txz|*.lzma|*.tlz)     xz -d "$1"                           ;;
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
       *.tar.bz2|*.tbz2|*.tbz) tar -jtf "$1"     ;;
       *.tar.gz)                     tar -ztf "$1"     ;;
       *.tar|*.tgz|*.tar.xz)                 tar -tf "$1"     ;;
       *.gz)                 gzip -l "$1"     ;;
       *.rar)                 rar vb "$1"     ;;
       *.zip)                 unzip -l "$1"     ;;
       *.7z)                 7z l "$1"     ;;
       *.lzo)                 lzop -l "$1"     ;;
       *.xz|*.txz|*.lzma|*.tlz)      xz -l "$1"     ;;
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
