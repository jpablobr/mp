#!/bin/sh
# git.sh
# Git related helper functions
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

ANSI_RESET="\001$(git config --get-color "" "reset")\002"

##############################################################################->
# Git Aliases
alias g-ungit="find . -name '.git' -exec rm -rf {} \;"
alias g-a='git add'
alias g-a.='git add .'
alias g-ap='git add -p'
alias g-b='git branch'
alias g-ph='git push heroku master'
alias g-pg='git push github master'
alias g-ca='git commit -v -a'
alias g-co="git checkout"
alias g-count='git shortlog -sn'
alias g-d='git diff'
alias g-dh='git diff HEAD'
alias g-dm='git diff master'
alias g-ds='git diff --cached'
alias g-dv='git diff -w "$@" | emq -R -'
alias g-itx='gitx --all'
alias g-pr='git pull --rebase || (notify "pull failed" "Git" && false)'
alias g-pru='gp && rake && gu'
alias g-ri='git rebase -i origin/master^'
alias g-rc='git rebase --continue'
alias g-up='git fetch && git rebase'
alias g-cache='git rm -r --cached .'
# http://www.jukie.net/~bart/blog/pimping-out-git-log
alias g-tl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%an %cr)%Creset' --abbrev-commit --date=relative"
# Dropbox
alias g-dbox='cd ~/Dropbox && git add . && g-gg updates and backup && gp && cd -'

gp() {
    test $# != 2 && git push && return 0
    git push "$1" "$2"
}

g-prune() {
    git remote | xargs -n 1 git remote prune
}

# Commit pending changes and quote all args as message
g-gg() {
    git commit -v -a -m "$*"
}

g-cn() {
    git clone "$1" "$2"
}

gc() {
    git add . && git commit -v -a -m "$*" && git status
}

# Setup a tracking branch from [remote] [branch_name]
g-bt() {
    git branch --track $2 $1/$2 && git checkout $2
}

# Quickly clobber a file and checkout
g-rf() {
    rm $1
    git checkout $1
}

g-parse_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1]/'
}

g-notpushed() {
    curr_branch=$(git symbolic-ref -q HEAD | sed -e 's|^refs/heads/||')
    origin=$(git config --get "branch.$curr_branch.remote")
    origin=${origin:-origin}
    git log $@ $curr_branch ^remotes/$origin/$curr_branch
}

# Completely removes a given file from a git repo
g-rm() {
    git filter-branch --index-filter 'git rm --cached --ignore-unmatch $1' HEAD
    git push origin master --force
    rm -rf .git/refs/original/
    git reflog expire --expire=now --all
    git gc --prune=now
    git gc --aggressive --prune=now
}

g-thanks() {
    git log "$1" |
    grep Author: |
    sed 's/Author: \(.*\) <.*/\1/' |
    sort |
    uniq -c |
    sort -rn |
    sed 's/ *\([0-9]\{1,\}\) \(.*\)/\2 (\1)/'
}

g-gc() {
    set -- `du -ks`
    before=$1
    git reflog expire --expire=1.minute refs/heads/master && git fsck --unreachable && git prune && git gc
    set -- `du -ks`
    after=$1
    echo "Cleaned up $((before-after)) kb."
}

g-rb() {
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

g-i() {
    git init &&
    cat > .gitignore << -EOF-
## MAC OS
.DS_Store

## TEXTMATE
*.tmproj
tmtags

## EMACS
*~
\#*
.\#*

## VIM
*.swp

## PROJECT::GENERAL
coverage
rdoc
pkg

## PROJECT::SPECIFIC'
-EOF-
    git add . &&
    git commit -v -a -m "Initial commit" &&
    git status
    return 0
}

g-general-baks() {
 cd ~/Dropbox/private-dotfiles &&
 gc automated commit && gp

 cd ~/Dropbox/bond &&
 gc automated commit && gp
}

function rd {
  git branch > /dev/null 2>&1 || return 1
  cd "$(git rev-parse --show-cdup)"
}

function set_git_prompt {
  local last_commit_in_unix_time
  local now_in_unix_time
  local tmp_flags
  local flags
  local seconds_since_last_commit
  local minutes_since_last_commit
  local days_since_last_commit
  local minutes_so_far_today
  local branch
  local seconds_since_last_remote_check
  last_commit_in_unix_time=$(git log "HEAD" --pretty=format:%ct 2> /dev/null | sort | tail -n1)
  now_in_unix_time=$(date +%s)
  seconds_since_last_remote_check=$((now_in_unix_time - $BGP_LAST_REMOTE_CHECK))
  branch=$(git branch --no-color 2> /dev/null | grep '*' | sed 's/\*//g' | sed 's/ //g')
  tmp_flags=$(git status --porcelain 2> /dev/null | cut -c1-2 | sed 's/ //g' | cut -c1 | sort | uniq)
  flags="$(echo $tmp_flags | sed 's/ //g')"
  if [ $last_commit_in_unix_time ]; then
    seconds_since_last_commit=$(($now_in_unix_time - $last_commit_in_unix_time))
    minutes_since_last_commit="$(($seconds_since_last_commit/60))"
    if ((minutes_since_last_commit < 60)); then
      minutes_since_last_commit="\[\e[0;32m\]${minutes_since_last_commit}m\[\e[0m\]|"
    elif ((minutes_since_last_commit < 120)); then
      minutes_since_last_commit="\[\e[0;33m\]${minutes_since_last_commit}m\[\e[0m\]|"
    elif ((minutes_since_last_commit < 1440)); then
      minutes_since_last_commit="\[\e[0;31m\]${minutes_since_last_commit}m\[\e[0m\]|"
    else
      days_since_last_commit=$(($minutes_since_last_commit/1440))
      minutes_so_far_today=$(($minutes_since_last_commit - $days_since_last_commit*1440))
      minutes_since_last_commit="\[\e[0;31m\]${days_since_last_commit}d \[\e[0;31m\]${minutes_so_far_today}m\[\e[0m\]|"
    fi
  else
    minutes_since_last_commit=""
  fi
  if [ $branch ] || [ $flags  ]; then
    if [[ "$BGP_GIT_ROOT_DIRECTORY" != $(git rev-parse --show-toplevel) ]]; then
      BGP_GIT_ROOT_DIRECTORY=$(git rev-parse --show-toplevel)
      BGP_LAST_REMOTE_CHECK=$((`date +%s` - 300))
      BGP_GIT_BRANCH=""
      BGP_GIT_REMOTE=""
      BGP_GIT_REMOTE_STATUS=""
    fi
    if [[ -e "$BGP_TMP_FILE" ]]; then
        source "$BGP_TMP_FILE"
        rm $BGP_TMP_FILE
    fi
    if ((seconds_since_last_remote_check > 60)); then
      BGP_LAST_REMOTE_CHECK=$(date +%s)
    fi
    if [ $branch ]; then
      branch="\[\e[0;36m\]${branch}\[\e[0m\]"
    else
      branch="\[\e[0;36m\]waiting for first commit\[\e[0m\]"
    fi
    if [ $flags ]; then
      PS1="(${minutes_since_last_commit}${branch}|\[\e[0;35m\]${flags}\[\e[0m\])$BGP_GIT_REMOTE_STATUS ${BGP_ORIGINAL_PS1}"
    else
      PS1="(${minutes_since_last_commit}${branch})$BGP_GIT_REMOTE_STATUS ${BGP_ORIGINAL_PS1}"
    fi
  else
    PS1=$BGP_ORIGINAL_PS1
  fi
}
