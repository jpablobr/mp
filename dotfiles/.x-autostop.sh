#!/bin/sh

USER=`whoami`

# Save audio status (per user)
which alsactl && alsactl -f .asound.conf store &

# Stop some services
pkill -TERM -u $USER emacs
