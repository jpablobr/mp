#!/bin/bash

# the basics
: ${HOME=~}
: ${LOGNAME=$(id -un)}
: ${UNAME=$(uname)}

# complete hostnames from this file
: ${HOSTFILE=$HOME/.ssh/known_hosts}
: ${HOSTNAME=$(/bin/hostname)}
: ${INPUTRC=~/.inputrc}

# ----------------------------------------------------------------------
# - ENVIRONMENT CONFIGURATION:

# detect interactive shell
case "$-" in
    *i*) INTERACTIVE=yes ;;
    *)   unset INTERACTIVE ;;
esac

# detect login shell
case "$0" in
    -*) LOGIN=yes ;;
    *)  unset LOGIN ;;
esac

# ----------------------------------------------------------------------
# - $PATH:

# bin
PATH=/bin:/usr/bin:/usr/local/bin:$PATH

# sbin
PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH

# Haskell
[ -d ~/.cabal/bin ] && PATH=~/.cabal/bin:$PATH

# rvm
[ -s ~/.rvm/scripts/rvm ] && . ~/.rvm/scripts/rvm

#Java
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk
PATH=$JAVA_HOME/bin:$PATH

# ignore backups, CVS directories, python bytecode, vim swap files
FIGNORE="~:CVS:#:.pyc:.swp:.swa:apache-solr-*"

# history stuff
HISTCONTROL=ignoreboth
HISTFILESIZE=1000000
HISTSIZE=10000000
export HISTIGNORE="&:ls:[bf]g:exit"

# -------------------------------------------------------------------
# - USER SHELL ENVIRONMENT:

# Emacs mode
set -o emacs

# notify of bg job completion immediately
set -o notify
set meta-flag on
set convert-meta off
set output-meta on

# shell opts. see bash(1) for details
shopt -s cdspell >/dev/null 2>&1
shopt -s extglob >/dev/null 2>&1
shopt -s hostcomplete >/dev/null 2>&1
shopt -s interactive_comments >/dev/null 2>&1
shopt -u mailwarn >/dev/null 2>&1
shopt -s no_empty_cmd_completion  >/dev/null 2>&1
shopt -s dotglob >/dev/null 2>&1
shopt -s expand_aliases >/dev/null 2>&1
shopt -s huponexit >/dev/null 2>&1
shopt -s interactive_comments >/dev/null 2>&1
shopt -s cmdhist
shopt -s histappend

ulimit -S -c 0
umask 0022

# override and disable tilde expansion
_expand() {
    return 0
}

# -------------------------------------------------------------------
# - BASH COMPLETION:
test -z "$BASH_COMPLETION" && {
    bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
    test -n "$PS1" && test $bmajor -gt 1 && {
        # search for a bash_completion file to source
        for f in /usr/local/etc/bash_completion \
            /usr/pkg/etc/bash_completion \
            /opt/local/etc/bash_completion \
            /etc/bash_completion
        do
            test -f $f && {
                . $f
                break
            }
        done
    }
    unset bash bmajor bminor
}

# source completion directory definitions
for i in ~/bin/completions/*; do
    [[ ${i##*/} != @(*~|*.bak|*.swp|\#*\#|*.dpkg*|.rpm*) ]] &&
    [ \( -f $i -o -h $i \) -a -r $i ] && . $i
done

# ----------------------------------------------------------------------
# - PAGER / EDITOR:

# Less
# Get color support for 'less'
# --max-forw-scroll=4 --max-back-scroll=4"
# export LESSOPEN="|lesspipe.sh %s"
export LESS="--RAW-CONTROL-CHARS --shift 4"
export LESSOPEN="| /usr/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

# EDITOR
HAVE_EMACS=$(command -v emacs)
test -n "$HAVE_EMACS" &&
export VISUAL='emacsclient -c' &&
export EDITOR='emacsclient -c --alternate-editor emacs'

# PAGER
if test -n "$(command -v less)"; then
    PAGER="less -FirSwX"
    MANPAGER="less -FiRswX"
else
    PAGER=more
    MANPAGER="$PAGER"
fi

# Ack
export ACK_PAGER="$PAGER"
export ACK_PAGER_COLOR="$PAGER"

# Grep
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'

# Browser
export BROWSER='chromium'

# Man
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

# Ruby
export GEM_EDITOR=$EDITOR

# use gem-man(1) if available:
man () {
    gem man -s "$@" 2>/dev/null ||
    command man "$@"
}

# ----------------------------------------------------------------------
# - SSH
test -f ~/.ssh/environment &&
export SSH_ENV=~/.ssh/environment

[ -f ~/.ssh/known_hosts ] && {
    _ssh_hosts() {
        grep "Host " ~/.ssh/config 2> /dev/null | sed -e "s/Host //g"
        # http://news.ycombinator.com/item?id=751220
        cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["
    }
    complete -W "$(_ssh_hosts)" ssh
}

# ----------------------------------------------------------------------
# - Colors
dircolors="$(/bin/dircolors)"
test -n "$dircolors" && {
    COLORS=/etc/DIR_COLORS
    test -e /etc/DIR_COLORS.$TERM             && COLORS=/etc/DIR_COLORS.$TERM
    test -e ~/.dircolors.d/dircolors.256dark  && COLORS=~/.dircolors.d/dircolors.256dark
    test ! -e "$COLORS"                       && COLORS=
    eval `dircolors --sh $COLORS`
}

export CLICOLOR=1
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
export LS_OPTIONS='-s -F -T 0 --color=yes'

# ----------------------------------------------------------------------
# - Bash.d

[ -f ~/.bash.d/aliases.bash ] && . ~/.bash.d/aliases.bash
[ -f ~/.bash.d/path.bash ] && . ~/.bash.d/path.bash

for f in $(/bin/ls ~/.functions.d/); do
    [ -f ~/.functions.d/$f ] && . ~/.functions.d/$f
done

# - Prompt
[ -f /usr/share/git/completion/git-completion.bash ] && {
    . /usr/share/git/completion/git-completion.bash
}

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWSTASHSTATE=true

PROMPT_COMMAND=prompt_git_status_timer

# Misc stuff to source:
[ -f ~/bin/sh/bashmarks.sh ] && . ~/bin/sh/bashmarks.sh
[ -f ~/.private/bashrc ] && . ~/.private/bashrc

#-----------------------------------------------------------------------
# ~/bin && functions
jplb() {
    [ -d ~/bin ] && {
				local bin_dir=$(
            find ~/bin/                                              \
                -maxdepth 1                                          \
                -type d \( ! -regex '\(.*/.git\)\|\(.*/exclude\)' \) |
                cut -c 1-
				)

        for b in $bin_dir; do
            PATH="$b:$PATH"
        done
    }
}
jplb

export TERM=xterm

# condense $PATH entries
PATH=$(puniq $PATH)
MANPATH=$(puniq $MANPATH)

uname -npsr
uptime
