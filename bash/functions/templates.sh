#!/bin/sh
# templates.sh
# Templates related helper functions
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

t-rvmrc() {
  test $# != 1 && echo "Please provide a name for the gemset!" && return 1

  cat > .rvmrc << -EOF-
rvm use 1.9.2-p180@$1 --create
-EOF-
  return 0
}

t-database-yml() {
  test $# != 1 && echo "Please provide a name for the database.yml file!" && return 1

  cat > database.yml << -EOF-
defaults: &defaults
  adapter: postgresql
  encoding: unicode
  database: $1_development
  pool: 5
  host: 127.0.0.1

development:
  <<: *defaults

test:
  <<: *defaults
  database: $1_test

production:
  <<: *defaults
  database: $1_production
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
