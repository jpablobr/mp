#!/usr/bin/env bash

# the basics
: ${HOME=~}
: ${LOGNAME=$(id -un)}
: ${UNAME=$(uname)}

# complete hostnames from this file
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

installed() {
    [ -z $(which "$1") ] && {
        echo -e "\e[0;37;41m$1 not installed.\e[0m"
        return 1
    }
    which "$1"
}

exists() {
    [ ! -r "$1" ] && {
        echo -e "\e[0;37;41m$1 does not exist.\e[0m"
        return 1
    }
    return 0
}

# ----------------------------------------------------------------------
# - $PATH:

# bin
PATH=/bin:/usr/bin:/usr/local/bin:$PATH

# sbin
PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH

# Haskell
exists ~/.cabal/bin && PATH=~/.cabal/bin:$PATH

#Java
exists /usr/lib/jvm/java-7-openjdk && {
    export JAVA_HOME=/usr/lib/jvm/java-7-openjdk
    PATH=$JAVA_HOME/bin:$PATH
}

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
[ -n "$HAVE_EMACS" ] && {
    export VISUAL='emacsclient -c'
    export EDITOR='emacsclient -c --alternate-editor emacs'
}

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
export BROWSER='google-chrome'

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
# https://gist.github.com/1688857
export RUBY_HEAP_MIN_SLOTS=1000000
export RUBY_HEAP_SLOTS_INCREMENT=1000000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1
export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_HEAP_FREE_MIN=500000

# rvm
exists ~/.rvm/scripts/rvm && . ~/.rvm/scripts/rvm
# PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# use gem-man(1) if available:
man () {
    gem man -s "$@" 2>/dev/null ||
    command man "$@"
}

# ----------------------------------------------------------------------
# - SSH
: ${SSH_ENV=~/.ssh/environment}
: ${HOSTFILE=$HOME/.ssh/known_hosts}

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
dircolors="$(dircolors)"
[ -n "$dircolors" ] && {
    COLORS=/etc/DIR_COLORS
    exists ~/.dircolors.d/dircolors.256dark  && COLORS=~/.dircolors.d/dircolors.256dark
    test ! -e "$COLORS"                      && COLORS=
    eval `dircolors --sh $COLORS`
}

export CLICOLOR=1
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
export LS_OPTIONS='-s -F -T 0 --color=yes'

# ----------------------------------------------------------------------
# - Bash.d

exists ~/.bash.d/aliases.bash && . ~/.bash.d/aliases.bash;
exists ~/.bash.d/path.bash && . ~/.bash.d/path.bash;

for f in $(/bin/ls ~/.functions.d/); do
    exists ~/.functions.d/$f && . ~/.functions.d/$f;
done

# - Prompt
exists /usr/share/git/completion/git-completion.bash && {
    . /usr/share/git/completion/git-completion.bash
}

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWSTASHSTATE=true

[ "$(whoami)" = "jpablobr" ] && {
    PROMPT_COMMAND=prompt_git_status_timer
}

# Misc
exists ~/bin/sh/bashmarks.sh && . ~/bin/sh/bashmarks.sh
exists ~/.private/bashrc && . ~/.private/bashrc

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

export TERM='rxvt-256color'

# condense $PATH entries
PATH=$(puniq $PATH)
MANPATH=$(puniq $MANPATH)
