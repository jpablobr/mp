#!/bin/bash

black="\[\e[0;30m\]"
red="\[\e[0;31m\]"
green="\[\e[0;32m\]"
yellow="\[\e[0;33m\]"
blue="\[\e[0;34m\]"
purple="\[\e[0;35m\]"
cyan="\[\e[0;36m\]"
white="\[\e[0;37m\]"
orange="\[\e[33;40m\]"
reset_color="\[\e[39m\]"

ANSI_RESET="\001$(git config --get-color "" "reset")\002"

##############################################################################->
# Git Aliases
alias g_ungit="find . -name '.git' -exec rm -rf {} \;"
alias g_a='git add'
alias g_a.='git add .'
alias g_ap='git add -p'
alias g_b='git branch'
alias g_ph='git push heroku master'
alias g_pg='git push github master'
alias g_ca='git commit -v -a'
alias g_co="git checkout"
alias g_count='git shortlog -sn'
alias g_d='git diff'
alias g_dh='git diff HEAD'
alias g_dm='git diff master'
alias g_ds='git diff --cached'
alias g_dv='git diff -w "$@" | emq -R -'
alias g_itx='gitx --all'
alias g_pr='git pull --rebase || (notify "pull failed" "Git" && false)'
alias g_pru='gp && rake && gu'
alias g_ri='git rebase -i origin/master^'
alias g_rc='git rebase --continue'
alias g_up='git fetch && git rebase'
alias g_cache='git rm -r --cached .'
# http://www.jukie.net/~bart/blog/pimping-out-git-log
alias g_log="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%an %cr)%Creset' --abbrev-commit --date=relative"

gp() {
    [ $# -eq 1 ] && git push "$1" $(gbr) && exit 0
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

g_cn() {
    git clone "$1" "$2"
}

gc() {
    git add . && git commit -v -a -m "$*" && git status
}

# Setup a tracking branch from [remote] [branch_name]
g_bt() {
    git branch --track $2 $1/$2 && git checkout $2
}

g_parse_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1]/'
}

g_notpushed() {
    curr_branch=$(git symbolic-ref -q HEAD | sed -e 's|^refs/heads/||')
    origin=$(git config --get "branch.$curr_branch.remote")
    origin=${origin:-origin}
    git log $@ $curr_branch ^remotes/$origin/$curr_branch
}

# Completely removes a given file from a git repo
g_rm() {
    git filter-branch --index-filter 'git rm --cached --ignore-unmatch $1' HEAD
    git push origin master --force
    rm -rf .git/refs/original/
    git reflog expire --expire=now --all
    git gc --prune=now
    git gc --aggressive --prune=now
}

g_rb() {
    git push origin HEAD:refs/heads/$1
    git fetch origin &&
    git checkout -b $1 --track origin/$1
}

g_i() {
    git init &&
    [ ! -f .gitignore ] && cat > .gitignore << -EOF-
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
coverage/
rdoc/
pkg/

## PROJECT::SPECIFIC'
-EOF-
    git add . &&
    git commit -v -a -m "Initial commit" &&
    git status
}

g-remote() {
    echo "Running: git remote add origin ${GIT_HOSTING}:$1.git"
    git remote add origin $GIT_HOSTING:$1.git
}

g_first_push() {
    echo "Running: git push origin master:refs/heads/master"
    git push origin master:refs/heads/master
}

g_remove_missing_files() {
    git ls-files -d -z | xargs -0 git update-index --remove
}

# Adds files to git's exclude file (same as .gitignore)
g_local_ignore() {
    echo "$1" >> .git/info/exclude
}

# get a quick overview for your git repo
g_info() {
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

g_stats() {
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

# Prompt
git_status() {
    local last_commit_in_unix_time
    local now_in_unix_time
    local tmp_flags
    local flags
    local seconds_since_last_commit
    local minutes_since_last_commit
    local days_since_last_commit
    local minutes_so_far_today
    local branch
    last_commit_in_unix_time=$(git log "HEAD" --pretty=format:%ct 2> /dev/null | sort | tail -n1)
    now_in_unix_time=$(date +%s)
    branch=$(git branch --no-color 2> /dev/null | grep '*' | sed 's/\*//g' | sed 's/ //g')
    tmp_flags=$(git status --porcelain 2> /dev/null | cut -c1-2 | sed 's/ //g' | cut -c1 | sort | uniq)
    flags="$(echo $tmp_flags | sed 's/ //g')"
    if [ $last_commit_in_unix_time ]; then
        seconds_since_last_commit=$(($now_in_unix_time - $last_commit_in_unix_time))
        minutes_since_last_commit="$(($seconds_since_last_commit/60))"
        if ((minutes_since_last_commit < 60)); then
            minutes_since_last_commit="${green}${minutes_since_last_commit}m${reset_color}"
        elif ((minutes_since_last_commit < 120)); then
            minutes_since_last_commit="${yellow}${minutes_since_last_commit}m${reset_color}"
        elif ((minutes_since_last_commit < 1440)); then
            minutes_since_last_commit="${red}${minutes_since_last_commit}m${reset_color}"
        else
            days_since_last_commit=$(($minutes_since_last_commit/1440))
            minutes_so_far_today=$(($minutes_since_last_commit - $days_since_last_commit*1440))
            minutes_since_last_commit="${red}${days_since_last_commit}d ${minutes_so_far_today}m${reset_color}"
        fi
    else
        minutes_since_last_commit=""
    fi
    if [ $branch ] || [ $flags  ]; then
        if [ $branch ]; then
            branch="${branch}"
        else
            branch="waiting for first commit"
        fi
        if [ $flags ]; then
        # ?AM: Git file flags.
        # '?' for untracked files.
        # M modified   File has been modified
        # C copy-edit  File has been copied and modified
        # R rename-edit  File has been renamed and modified
        # A added  File has been added
        # D deleted  File has been deleted
        # U unmerged   File has conflicts after a merge
            echo -e " ${reset_color}${flags}|${minutes_since_last_commit}|${branch}${reset_color} "
        else
            echo -e " ${reset_color}${minutes_since_last_commit}|${branch}${reset_color} "
        fi
    else
        echo -e " "
    fi
}

p_me() {
    /usr/bin/whoami | /bin/cut -c1-2
}

p_hst() {
    /usr/bin/hostname | /bin/cut -c1
}

prompt_start() {
    if [ "$(/usr/bin/whoami)" = root ]; then
        no_color=$red
    else
        no_color=$white
    fi
		start_ps1="${no_color}$(p_me)@$(p_hst)${reset_color}:"
}

prompt_git_status_timer() {
		prompt_start
    PS1="${start_ps1}$(git_status)\`es=\$?;if [ ! \$es = 0 ];then echo \[\e[0\;31m\]\$es' ';else echo "";fi\`${blue}\W${reset_color} "
}

prompt_git_status_simple() {
		prompt_start
    PS1="${yellow}$(__git_ps1) ${start_ps1}\`es=\$?;if [ ! \$es = 0 ];then echo \[\e[0\;31m\]\$es' ';else echo "";fi\`${blue}\W$(tput sgr0) "
}

# Prompt toggle
jppt() {
		if [ $PROMPT_COMMAND = "prompt_git_status_simple" ]; then
				export PROMPT_COMMAND=prompt_git_status_timer
		else
				export PROMPT_COMMAND=prompt_git_status_simple
		fi
}
