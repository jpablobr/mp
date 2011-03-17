#!/bin/sh
# git.sh
# Git related helper functions
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 18 Mar 2011
# Version: 0.1.0

# Commit pending changes and quote all args as message
function gi_gg() {
    git commit -v -a -m "$*"
}

function gi_cn() {
    git clone "$1" "$2"
}

function gc() {
    git add . && git commit -v -a -m "$*" && git status
}

# Setup a tracking branch from [remote] [branch_name]
function gi_bt() {
    git branch --track $2 $1/$2 && git checkout $2
}
# Quickly clobber a file and checkout
function gi_rf() {
    rm $1
    git checkout $1
}

gi_gc() {
    set -- `du -ks`
    before=$1
    git reflog expire --expire=1.minute refs/heads/master && git fsck --unreachable && git prune && git gc
    set -- `du -ks`
    after=$1
    echo "Cleaned up $((before-after)) kb."
}

gi_rb() {
    git push origin HEAD:refs/heads/$1
    git fetch origin &&
    git checkout -b $1 --track origin/$1
}

current_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

git_commits_ahead() {
    git status 2> /dev/null | grep ahead | sed -e 's/.*by \([0-9]\{1,\}\) commits\{0,1\}\./\1/'
}
ANSI_RESET="\001$(git config --get-color "" "reset")\002"

    # detect the current branch; use 7-sha when not on branch
_git_headname() {
	  local br=`git symbolic-ref -q HEAD 2>/dev/null`
	  [ -n "$br" ] &&
		br=${br#refs/heads/} ||
		br=`git rev-parse --short HEAD 2>/dev/null`
	  _git_apply_color "$br" "color.sh.branch" " yellow reverse"
}

    # determine whether color should be enabled. this checks git's color.ui
    # option and then color.sh.
_git_color_enabled() {
	  [ `git config --get-colorbool color.sh true` = "true" ]
}

    # apply a color to the first argument
_git_apply_color() {
	  local output="$1" color="$2" default="$3"
	  if _git_color_enabled ; then
		    color=`_git_color "$color" "$default"`
		    echo -ne "${color}${output}${ANSI_RESET}"
	  else
		    echo -ne "$output"
	  fi
}

    # retrieve an ANSI color escape sequence from git config
_git_color() {
	  local color
	  color=`git config --get-color "$1" "$2" 2>/dev/null`
	  [ -n "$color" ] && echo -ne "\001$color\002"
}
