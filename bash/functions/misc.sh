#!/usr/bin/env bash
# misc.sh
# General helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

##############################################################################->
# - Grep
g-.() { grep -nH -e "$@";}
g-f() { find . -type f -print0 | xargs -0 -e grep -nH -e "$1"; }
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
    dropbox stop &&
    sudo sysctl fs.inotify.max_user_watches=1000000 &&
    dropbox start;
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

jp-init() {
    ~/.private/bin/jpablobr-startups.sh >> ~/logs/jpablobr-startups.sh.log
}
