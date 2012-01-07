#!/bin/sh
# templates.sh
# Templates related helper functions
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>

t-rvmrc() {
  test $# != 1 \
      && echo "Please provide a name for the gemset!" \
      && return 1

  cat > .rvmrc << -EOF-
rvm use ruby-1.9.2-p290@$1
-EOF-
  return 0
}

t-database-yml() {

  test ! -f ./config.ru \
      &&  echo "You have to be in a Rails root dir!" \
      &&  echo "Current directory:" `pwd` \
      &&  return 1

  test $# != 1 \
      && echo "Please provide a name for the database.yml file!" \
      && return 1

  cat > config/database.yml << -EOF-
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
.bundle
tmp
log
logs
.idea/**# Rails
.bundle
db/*.sqlite3
db/*.sqlite3-journal
*.log

# Documentation
.yardoc
.yardopts

# Public Uploads
public/system/*
public/themes/*

# Public Cache
public/javascripts/cache
public/stylesheets/cache

# Vendor Cache
vendor/cache

# Acts as Indexed
index/**/*

# Mac
.DS_Store

# Windows
Thumbs.db

# NetBeans
.nbproject

# Eclipse
.project

# Redcar
.redcar

# Rubinius
*.rbc

# Vim
*.swp
*.swo

# RubyMine
.idea

# Backup
*~

# Capybara Bug
capybara-*html

# sass
.sass-cache

-EOF-
  return 0
}
