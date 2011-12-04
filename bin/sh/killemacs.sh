#!/usr/bin/env bash

#
#  File: killemacs.sh
#  Description: Save all buffers and stop emacs daemon
#
#  Version: killemacs.sh, 2010/08/26 12:35:15 EEST
#  Copyright © 2010 Vladyslav Semyonov <vsemyonoff@gmail.com>
#

emacsclient --eval "(progn (save-some-buffers t) (setq kill-emacs-hook 'nil) (kill-emacs))" &>/dev/null && \
    rm -rf "/tmp/emacs`id -u`"

# End of killemacs.sh
