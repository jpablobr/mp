#!/bin/sh
# templates.sh
# Templates related helper functions
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

t-rvmrc() {
  test $# != 1 && echo "Please pass a name for the gemset!" && return 1

  cat > .rvmrc << -EOF-
rvm use 1.9.2-p180@$1 --create
-EOF-
  return 0
}

t-gitignore() {
  cat > .gitignore << -EOF-
## MAC OS
.DS_Store

## TEXTMATE
*.tmproj
tmtags

## EMACS
*~
\#*
.\#*

## VIM
*.swp

## PROJECT::GENERAL
coverage
rdoc
pkg

## PROJECT::SPECIFIC'
-EOF-
  return 0
}
