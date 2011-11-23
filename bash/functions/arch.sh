#!/usr/bin/env bash
# arch.sh
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

# archlinux aliases
# colorize pacman (pacs)
alias pac="pacsearch"
alias pacs="pacman -Sl | cut -d' ' -f2 | grep "
alias pacq="pacman -Qi"
# sync and update
alias pacup="sudo pacman -Syu"
alias pacls="pacman -Ql"
# install pkg
alias pacin="sudo pacman -S"
# remove pkg and the deps it installed
alias pacout="sudo pacman -Rns"

#FUNCTIONS ------------------------------------------------------------------
pacsearch() {
  echo -e "$(pacman -Ss $@ | sed \
  -e 's#core/.*#\\033[1;31m&\\033[1;30m#g' \
  -e 's#extra/.*#\\033[1;34m&\\033[1;30m#g' \
  -e 's#community/.*#\\033[0;32m&\\033[1;30m#g' \
  -e 's#^.*/.* [0-9].*#\\033[0;36m&\\033[1;30m#g' )"
}
