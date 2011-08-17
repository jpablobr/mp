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
db/production.sqlite3
db/development.sqlite3
log
logs
tmp
.idea/**# Rails
.bundle
db/*.sqlite3
db/*.sqlite3-journal
*.log

# Documentation
doc/api
doc/app
doc/*
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
nbproject

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
.sass-cache/*

#rvm
.rvmrc
.rvmrc.*
-EOF-
  return 0
}

t-gemfile() {
  cat > Gemfile << -EOF-
source :rubygems

gem 'rails', '3.0.7'
gem 'pg'
gem 'compass'
gem 'haml'
gem "html5-boilerplate"

group :development, :test do
  gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'rack-debug', :require => "rack/debug"
  ### test
  gem 'spork'
  gem 'database_cleaner'
  gem 'rspec-rails', '~> 2.5.0'
  gem 'autotest-rails', '4.1.0'
  gem 'rr', '1.0.2'
  gem 'factory_girl_rails', '1.0'
  gem 'email_spec', '1.0.0'
  gem 'webmock', '1.6.1', :require => false
  gem 'ZenTest'
  ### console
  gem 'awesome_print'
  gem 'wirble'
  ### misc
  gem 'rcov', '0.9.9'
  gem 'heroku'
  gem 'rails3-generators', '0.14.0'
  gem 'railroady'
  gem 'rdoc'
  gem "niftier-generators", :git => 'git://github.com/jpablobr/niftier-generators.git'
end

# gem 'taps'
# gem 'sequel'
# gem 'aws-s3', :require => 'aws/s3'
# gem 'sqlite3'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'friendly_id', :git => 'git://github.com/parndt/friendly_id.git'
-EOF-
  return 0
}
