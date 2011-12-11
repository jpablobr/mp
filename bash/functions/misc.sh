#!/usr/bin/env bash

alias pygrep="grep --include='*.py' $*"
alias rbgrep="grep --include='*.rb' $*"
alias ducks="du -cksh * |sort -rn |head -10" # print top 10 largest files in pwd
alias psm="echo '%CPU %MEM   PID COMMAND' && ps hgaxo %cpu,%mem,pid,comm | sort -nrk1 | head -n 10 | sed -e 's/-bin//' | sed -e 's/-media-play//'"
alias chmodfx="find . -type f -print0 | xargs -0 chmod +x"
alias scan="sudo iwlist wlan0 scan | grep ESSID"
alias scanfull="sudo iwlist wlan0 scan"
alias grep="grep --color=auto"
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

debug_http () {
    /usr/bin/curl    \
        $@           \
        -o /dev/null \
        -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n"
}

# http_headers: get just the HTTP headers from a web page (and its redirects)
http_headers () {
    /usr/bin/curl -I -L $@
}
