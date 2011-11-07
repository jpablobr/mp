#!/bin/bash
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

function g-remote {
    echo "Running: git remote add origin ${GIT_HOSTING}:$1.git"
    git remote add origin $GIT_HOSTING:$1.git
}

function g-first_push {
    echo "Running: git push origin master:refs/heads/master"
    git push origin master:refs/heads/master
}

function g-remove_missing_files() {
    git ls-files -d -z | xargs -0 git update-index --remove
}

# Adds files to git's exclude file (same as .gitignore)
function local-ignore() {
    echo "$1" >> .git/info/exclude
}

# get a quick overview for your git repo
function g-info() {
    if [ -n "$(git symbolic-ref HEAD 2> /dev/null)" ]; then
        # print informations
        echo "git repo overview"
        echo "-----------------"
        echo

        # print all remotes and thier details
        for remote in $(git remote show); do
            echo $remote:
            git remote show $remote
            echo
        done

        # print status of working repo
        echo "status:"
        if [ -n "$(git status -s 2> /dev/null)" ]; then
            git status -s
        else
            echo "working directory is clean"
        fi

        # print at least 5 last log entries
        echo
        echo "log:"
        git log -5 --oneline
        echo

    else
        echo "you're currently not in a git repository"

    fi
}

function g-stats {
# awesome work from https://github.com/esc/git-stats
# including some modifications

    if [ -n "$(git symbolic-ref HEAD 2> /dev/null)" ]; then
        echo "Number of commits per author:"
        git --no-pager shortlog -sn --all
        AUTHORS=$( git shortlog -sn --all | cut -f2 | cut -f1 -d' ')
        LOGOPTS=""
        if [ "$1" == '-w' ]; then
            LOGOPTS="$LOGOPTS -w"
            shift
        fi
        if [ "$1" == '-M' ]; then
            LOGOPTS="$LOGOPTS -M"
            shift
        fi
        if [ "$1" == '-C' ]; then
            LOGOPTS="$LOGOPTS -C --find-copies-harder"
            shift
        fi
        for a in $AUTHORS
        do
            echo '-------------------'
            echo "Statistics for: $a"
            echo -n "Number of files changed: "
            git log $LOGOPTS --all --numstat --format="%n" --author=$a | cut -f3 | sort -iu | wc -l
            echo -n "Number of lines added: "
            git log $LOGOPTS --all --numstat --format="%n" --author=$a | cut -f1 | awk '{s+=$1} END {print s}'
            echo -n "Number of lines deleted: "
            git log $LOGOPTS --all --numstat --format="%n" --author=$a | cut -f2 | awk '{s+=$1} END {print s}'
            echo -n "Number of merges: "
            git log $LOGOPTS --all --merges --author=$a | grep -c '^commit'
        done
    else
        echo "you're currently not in a git repository"
    fi
}