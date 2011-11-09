#!/usr/bin/env bash

set -e

emacs -l ~/.emacs.d/inits/ruby-init.el . &

exec xterm
