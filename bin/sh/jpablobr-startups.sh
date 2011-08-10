#!/usr/bin/env bash

set -e

xfce4-terminal --working-directory \
--hide-menubar \
--maximize \
-e '/bin/bash /home/jpablobr/.tmuxinator/jpablobr.tmux'