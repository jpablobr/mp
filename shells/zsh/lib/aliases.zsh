#!/bin/zsh

# Push and pop directories on directory stack
alias pu='pushd'
alias po='popd'
alias tss='thin --stats "/thin/stats" start'

# Basic directory operations
alias .='pwd'
alias ...='cd ../..'
alias -- -='cd -'

# Super user
alias _='sudo'
alias ss='sudo su -'

# Show history
alias history='fc -l 1'

# List direcory contents
alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -alr'

# Command Enhancements

alias start="gnome-open"
alias open="gnome-open"

# changing directory to code project
function c { cd ~/code/$1; }

#Emacs
alias ec='emacsclient -nw'
alias sec='emacsclient -nw'

# Utility
alias reload='source ~/bin/dotfiles/bash/aliases'
alias ea='ec -w ~/bin/dotfiles/bash/aliases && reload' # Edit aliases
alias ee="ec ~/bin/dotfiles/bash/env"
alias sagi='sudo apt-get install'
alias agi='apt-get install'

# Common -- Some are from Damian Conway
alias a='ls -A' # -A all except literal . ..
alias la="ls -A -l -G"
# alias c='clear'
alias cdd='cd -'  # goto last dir cd'ed from
alias cl='clear; l'
function cdc() {
    cd $1; ls
}
alias cls='clear; ls'
alias h='history'
alias l.='ls -d .[^.]*'
alias l='ls -lhGt'  # -l long listing, most recent first
                    # -G color
alias lh="ls -lh"
alias ll='ls -lhG'  # -l long listing, human readable, no group info
alias lt='ls -lt' # sort with recently modified first
alias md='mkdir -p'
alias s='cd ..'   # up one dir

alias pidips='sudo lsof -iTCP -sTCP:LISTEN -P'

function take() {
    mkdir -p "$1"
    cd "$1"
}

alias e='exit'
alias k9="killall -9"

function zipr() {
  zip -r $1.zip $1
}

# Finder
alias ff='firefox'

# General code

# Processes
alias tu='top -p cpu' # cpu
alias tm='top -p vsize' # memory

# Text editing
# Emacs
alias em=/usr/bin/emacsclient
alias emm=/usr/bin/emacsclient

# Regenerate TAGS file from file arguments
function ct() {
  rm -f TAGS
  etags --append --output=TAGS $*
}

# Setup a tunnel
function haproxyssh() {
  ssh -L7997:127.0.0.1:7997 deploy@$1.com
}

# Syntax check Javascript
function jsc() {
  jsl -conf /etc/jsl/jsl.conf -process $1
}

function aiff2mp3() {
  lame -h -V 0 $1.aif $1.mp3
}
function wav2mp3() {
  lame -h -V 0 $1.wav $1.mp3
}

# Nginx
function nginx_stop() {
    ps ax | grep nginx | cut -d " " -f 1 | xargs sudo kill -9
}
function nginx_start() {
    sudo /opt/nginx/sbin/nginx
}

# TaskPaper
function new-tp() {
    touch $1.taskpaper
    open $1.taskpaper
}

# From http://github.com/suztomo/dotfiles
function rmf(){
    for file in $*
    do
        __rm_single_file $file
    done
}

function __rm_single_file(){
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
