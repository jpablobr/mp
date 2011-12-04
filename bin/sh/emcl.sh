#!/usr/bin/env bash

EMACS="emacsclient --alternate-editor="

case "$1" in
    --nofork)
        NOFORK=1
        shift
        ;;
    --tty|-nw|-t)
        NOFORK=1
        ;;
    *)
        ;;
esac

[ -z "${DISPLAY}" ] && NOFORK=1 && FRAME="--tty" || FRAME="--create-frame"
[ -z "${NOFORK}" ] && FORKARGS=">/dev/null 2>&1 &"

eval 'exec ${EMACS} ${FRAME} "$@"' ${FORKARGS}
