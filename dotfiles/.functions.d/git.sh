#!/usr/bin/env bash

gup() {
    git pull --rebase origin $(gbr)
}

gbr() {
    test -d .git && git symbolic-ref HEAD 2> /dev/null | cut -d/ -f3
}

gct() {
    git add .
    git commit -v -a -m "$*"
    git status
}

# get a quick overview for your git repo
ginfo() {
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

gstat() {
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
            minutes_since_last_commit="\e[0;32m\]${minutes_since_last_commit}m\e[0m\]"
        elif ((minutes_since_last_commit < 120)); then
            minutes_since_last_commit="\e[0;33m\]${minutes_since_last_commit}m\e[0m\]"
        elif ((minutes_since_last_commit < 1440)); then
            minutes_since_last_commit="\e[0;31m\]${minutes_since_last_commit}m\e[0m\]"
        else
            days_since_last_commit=$(($minutes_since_last_commit/1440))
            minutes_so_far_today=$(($minutes_since_last_commit - $days_since_last_commit*1440))
            minutes_since_last_commit="\e[0;31m\]${days_since_last_commit}d ${minutes_so_far_today}m\e[0m\]"
        fi
    else
        minutes_since_last_commit=""
    fi
    if [ $branch ] || [ $flags  ]; then
        if [ $branch ]; then
            branch="$branch"
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
            echo -e " \e[0m\]$flags|$minutes_since_last_commit|$branch\e[0m\] "
        else
            echo -e " \e[0m\]$minutes_since_last_commit|$branch\e[0m\] "
        fi
    else
        echo -e " "
    fi
}

prompt_git_status_timer() {
    PS1="\u@\h$(git_status)\`es=\$?;if [ ! \$es = 0 ];then echo \$es;else echo "";fi\`\e[0;34m\W\e[0m "
}

prompt_git_status_simple() {
    PS1="\u@\h\W$(__git_ps1)\$ "
}

# Prompt toggle
jppt() {
    if [ "$PROMPT_COMMAND" = "prompt_git_status_timer" ]; then
        export PROMPT_COMMAND=prompt_git_status_simple
    else
        export PROMPT_COMMAND=prompt_git_status_timer
    fi
}
