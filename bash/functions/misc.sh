#!/bin/sh
# misc.sh
# General helpers
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 18 Mar 2011
# Version: 0.1.0

##############################################################################->
# - General

# Regenerate TAGS file from file arguments
tags_regenerate() {
    rm -f TAGS
    etags --append --output=TAGS $*
}

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

##############################################################################->
# - Browsing
br-gh() { br-c "https://github.com/$1"; }
br-t() { br-c "https://twitter.com/$1"; }
br-g() { br-c "http://www.google.com/search?q=$1"; }

##############################################################################->
# - Grep
g-.() { grep -nH -e "$@";}
g-f() { find . -type f -print0 | xargs -0 -e grep -nH -e "$1"; }
gr-fp() { find "$1" -type f -print0 | xargs -0 -e grep -nH -e "$2"; }
gr-aliases() { grep -nH -e "$@" ~/.my-precious/bash/aliases; }
gr-linux-yac() { grep -nH -e "$@" ~/org/yacs/linux.org; }
gr-less() { egrep --color=yes "$@" | less -R; }

##############################################################################->
# - Sed
sed-f() { sed -i s/${1}/${2}/g "$3" ;}
sed-r() { find . -type f | xargs sed -i "s/"$1"/"$2"/g";}
sed-rp() { find "$1" -type f | xargs sed -i "s/"$2"/"$3"/g" ;}
# Instead of editing all files only files containg a certain string.
sed-g() { grep -rl "$1" . | xargs sed -i "s/"$2"/"$3"/g"; }
# grep -rl WHAT WHERE | xargs sed -i s/WHAT/WITH/g
sed-gp() { grep -rl $1 $2 | xargs sed -i s/"$4"/"$5"/g ; }

##############################################################################->
# - Common
m() { cd ~/.my-precious/$1 && ls --format=long; }
d() { cd ~/Dropbox/$1 && ls --format=long; }
t() { cd ~/todo/$1 && ls --format=long; }
c() { cd ~/code/$1 && ls --format=long; }
tmp() { cd ~/tmp/$1 && ls --format=long; }
yas() { cd ~/.emacs.d/vendor/snippets/yasnippets-jpablobr/$1 && ls --format=long; }

##############################################################################->
# - Severs
nginx-stop() {
    ps ax | grep nginx | cut -d " " -f 1 | xargs sudo kill -9
}

nginx-start() {
    sudo /opt/nginx/sbin/nginx
}

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