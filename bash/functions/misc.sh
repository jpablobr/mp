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

# Syntax check Javascript
jsc() {
    jsl -conf /etc/jsl/jsl.conf -process $1
}

myip() {
    curl --silent 'www.whatismyip.com/automation/n09230945.asp' && echo
}

knpviewer() {
    for name in $(ps ux | awk '/npviewer.bin/ && !/awk/ {print $2}'); do
        kill "$name"
    done
}

last_modified(){
    ls -t $* 2> /dev/null | head -n 1
}

rails_app() {
    rails $2 -m http://github.com/ryanb/rails-templates/raw/master/$1.rb $*[3,-1]
}

##############################################################################->
# - Compression

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

function dbox_bitch {
    dropbox stop &&
    sudo sysctl fs.inotify.max_user_watches=100000 &&
    dropbox start;
}

##############################################################################->
# - Browsing
function br_gh { br_c "https://github.com/$1"; }
function br_t { br_c "https://twitter.com/$1"; }
function br_g { br_c "http://www.googlecom/search?q=$1"; }

##############################################################################->
# - Grep
function g_. { grep -nH -e "$@";}
function g_f { find "$1" -type f -print0 | xargs -0 -e grep -nH -e "$2"; }
function g_aliases { grep -nH -e "$@" ~/.my-precious/bash/aliases; }
function g_linux_yac { grep -nH -e "$@" ~/org/yacs/linux.org; }
function g_less { egrep --color=yes "$@" | less -R; }

##############################################################################->
# - Grep
function e { cd ~/.emacs.d/$1 && ls --format=long; }
function m { cd ~/.my-precious/$1 && ls --format=long; }
function d { cd ~/Dropbox/$1 && ls --format=long; }
function t { cd ~/todo/$1 && ls --format=long; }
function c { cd ~/code/$1 && ls --format=long; }
function tmp { cd ~/tmp/$1 && ls --format=long; }
function yas { cd ~/.emacs.d/vendor/snippets/yasnippets-jpablobr/$1 && ls --format=long; }

##############################################################################->
# - Severs
function nginx_stop() {
    ps ax | grep nginx | cut -d " " -f 1 | xargs sudo kill -9
}
function nginx_start() {
    sudo /opt/nginx/sbin/nginx
}

##############################################################################->
# - Databases
function loaddb {
    mysql -u root $1 < $1.sql
}

function dumpdb {
    mysqldump -u root --add-drop-table --no-create-db $1 > $1.sql
}

function dumpschema {
    mysqldump -u root --add-drop-table --no-create-db --no-data $1 > schema.s
}
function GET() {
  curl -i -X GET -H "X-Requested-With: XMLHttpRequest" $*
}

function POST() {
  curl -i -X POST -H "X-Requested-With: XMLHttpRequest" $*
  #-d "key=val"
}

function PUT() {
  curl -i -X PUT -H "X-Requested-With: XMLHttpRequest" $*
}

function DELETE() {
  curl -i -X DELETE -H "X-Requested-With: XMLHttpRequest" $*
}

function command_not_found_handler() {
  /usr/bin/env ruby ~/bin/method_missing.rb $*
}

# Bash (call Zsh version)
function command_not_found_handle() {
  command_not_found_handler $*
  return $?
}

function json() {
  tmpfile=`mktemp -t json`
  curl -s $* | python -mjson.tool > $tmpfile
  cat $tmpfile
  cat $tmpfile | pbcopy
  rm $tmpfile
}

function xml() {
  tmpfile=`mktemp -t xml`
  curl -s $* | xmllint —format - > $tmpfile
  cat $tmpfile
  cat $tmpfile | pbcopy
  rm $tmpfile
}