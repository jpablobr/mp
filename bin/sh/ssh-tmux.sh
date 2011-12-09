#!/bin/sh

[ "$1" ] || return 1
REMOTE="$1"
ssh -t $REMOTE 'tmux attach || tmux'
