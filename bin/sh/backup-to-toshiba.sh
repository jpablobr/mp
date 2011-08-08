#!/bin/sh

rsync -auzvr --delete --exclude-from \
    $HOME/.rsync-exclude /home/jpablobr/ \
    /media/toshiba-1t/rsync-jpablobr/

