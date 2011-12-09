#!/bin/sh

[ "$3" ] || return 1
HOST="$1"
LOCAL="$2"
REMOTE="$3"

ssh -fLN $LOCAL:$HOST:$REMOTE $HOST
