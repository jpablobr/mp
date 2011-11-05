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
alias g-log="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%an %cr)%Creset' --abbrev-commit --date=relative"
# Dropbox
alias g-dbox='cd ~/Dropbox && git add . && g-gg updates and backup && gp && cd -'

gp() {
    [ $# -eq 1 ] && git push "$1" $(gbr) && return 0
    git push origin $(gbr)
}

gup() {
  git pull --rebase origin $(gbr)
}

gbr() {
  test -d .git && git symbolic-ref HEAD 2> /dev/null | cut -d/ -f3
}

g-prune() {
    git remote | xargs -n 1 git remote prune
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
