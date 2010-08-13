#!/bin/zsh

# Push and pop directories on directory stack
alias pu='pushd'
alias po='popd'

alias ss='thin --stats "/thin/stats" start'
alias sg='ruby script/generate'
alias sd='ruby script/destroy'
alias sp='ruby script/plugin'
alias ssp='ruby script/spec'
alias rdbm='rake db:migrate'
alias sc='ruby script/console'
alias sd='ruby script/server --debugger'
alias devlog='tail -f log/development.log'

# Basic directory operations
alias .='pwd'
alias ...='cd ../..'
alias -- -='cd -'

# Super user
alias _='sudo'
alias ss='sudo su -'

#alias g='grep -in'

# Show history
alias history='fc -l 1'

# List direcory contents
alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -alr'
alias sl=ls # often screw this up

alias sgem='sudo gem'

# Find ruby file
alias rfind='find . -name *.rb | xargs grep -n'
alias afind='ack-grep -il'

# Command Enhancements

# changing directory to code project
function c { cd ~/code/$1; }

# alternative to "rails" command to use templates
function railsapp {
  template=$1
  appname=$2
  shift 2
  rails $appname -m http://github.com/ryanb/rails-templates/raw/master/$template.rb $@
}

# misc
alias reload='. ~/.bash_profile'

#Emacs
alias ec='open /Applications/Emacs.app/'

# Utility
alias reload='source ~/bin/dotfiles/bash/aliases'
alias ea='ec -w ~/bin/dotfiles/bash/aliases && reload' # Edit aliases
alias ee="ec ~/bin/dotfiles/bash/env"

# Quicker cd
alias cg='cd /Library/Ruby/Gems/1.8/gems/'
function cr() {
 cd ~/repos/$*
}

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

function take() {
    mkdir -p "$1"
    cd "$1"
}

alias e='exit'
alias k9="killall -9"
function killnamed () {
    ps ax | grep $1 | cut -d ' ' -f 2 | xargs kill
}
function zipr() {
  zip -r $1.zip $1
}

# Finder
alias o='open . &'
alias ff='open -a Firefox'

# General code

# From Chris Wanstrath
function pless() {
    pygmentize $1 | less -r
}

# Processes
alias tu='top -o cpu' # cpu
alias tm='top -o vsize' # memory

# Mercurial hg
function new-hg() {
    ssh hg@example.com "hg init $1"
    hg clone ssh://hg@example.com/$1
}



# Text editing
# Emacs
alias em="open /Applications/Emacs.app/"
alias emm="open /Applications/Emacs.app/ ."
# Regenerate TAGS file from file arguments
function ct() {
  rm -f TAGS
  etags --append --output=TAGS $*
}

# TextMate
alias et="mate"
alias ett="mate ."
alias etr="mate app config lib db schema public spec test vendor/gems vendor/plugins Rakefile Capfile Vladfile Todofile README stories merb slices tasks features &"

# Ruby
alias r="rake"

function markdown() {
/Applications/TextMate.app/Contents/SharedSupport/Support/bin/Markdown.pl $1 > $1.html
}

# Rails
alias mr='mongrel_rails start'
alias ms='mongrel_rails stop'
alias rp='touch tmp/restart.txt'
alias sc='./script/console'
alias sg='./script/generate'
alias sp='./script/plugin'
alias ss='./script/server'
alias tl='tail -f log/*.log'
alias ts='thin start'

# TDD / BDD

alias aa='autotest'
alias aaf='autotest -f' # Don't run all at start
alias aas="./script/autospec"

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


# XCode
# Analyze release build
alias sx="xcodebuild clean && ~/src/checker-0.146/scan-build -k -V xcodebuild"
# Analyze test build
alias sxt="xcodebuild -target Test clean && ~/src/checker-0.146/scan-build -k -V xcodebuild -target Test"
# Call with -target Foo
function sxx() {
  xcodebuild $* clean && ~/src/checker-0.146/scan-build -k -V xcodebuild $*
}

alias ox="open *.xcodeproj"

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
