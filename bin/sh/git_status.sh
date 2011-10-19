#!/usr/bin/env bash

set -e

function git_status {
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
      minutes_since_last_commit="$(tput setaf 2)${minutes_since_last_commit}m$(tput op)"
    elif ((minutes_since_last_commit < 120)); then
      minutes_since_last_commit="$(tput setaf 3)${minutes_since_last_commit}m$(tput op)"
    elif ((minutes_since_last_commit < 1440)); then
      minutes_since_last_commit="$(tput setaf 1)${minutes_since_last_commit}m$(tput op)"
    else
      days_since_last_commit=$(($minutes_since_last_commit/1440))
      minutes_so_far_today=$(($minutes_since_last_commit - $days_since_last_commit*1440))
      minutes_since_last_commit="$(tput setaf 1)${days_since_last_commit}d ${minutes_so_far_today}m$(tput op)"
    fi
  else
    minutes_since_last_commit=""
  fi
  if [ $branch ] || [ $flags  ]; then
    if [ $branch ]; then
      branch="$(tput setaf 6)${branch}$(tput op)"
    else
      branch="$(tput setaf 6)waiting for first commit$(tput op)"
    fi
    if [ $flags ]; then
        # ?AM: Git file flags.
        # '?' for untracked files.
        # 'A' for newly added uncommited files.
        # 'M' for modified uncommited files.
        echo -e "(${minutes_since_last_commit}|${branch}|$(tput setaf 5)${flags}$(tput op))"
    else
        echo -e "(${minutes_since_last_commit}|${branch}))"
    fi
  fi
}; git_status && exit 0