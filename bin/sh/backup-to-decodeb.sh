#!/bin/sh

rsync -e ssh -auzvr --delete --exclude-from \
    $HOME/.rsync-exclude /home/jpablobr/ \
    decodeb:/media/toshiba-1t/rsync-jpablobr/
