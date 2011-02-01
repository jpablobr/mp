#!/bin/zsh

alias sgem='sudo gem'
alias sgemi='sudo gem install'
alias gemi='gem install'
alias bi='bundle install'

# Find ruby file
alias rfind='find . -name *.rb | xargs grep -n'
alias afind='ack-grep -il'

# Rails
alias mr='mongrel_rails start'
alias ms='mongrel_rails stop'
alias rp='touch tmp/restart.txt'
alias sg='./script/generate'
alias ss='./script/server'
alias tl='tail -f log/*.log'
alias ts='thin start'
alias sg='ruby script/generate'
alias sd='ruby script/destroy'
alias sp='ruby script/plugin'
alias ssp='ruby script/spec'
alias rdbm='rake db:migrate'
alias sc='ruby script/console'
alias sd='ruby script/server --debugger'
alias devlog='tail -f log/development.log'
alias r="rake"
# TDD / BDD

alias aa='autotest'
alias aaf='autotest -f' # Don't run all at start
alias aas="./script/autospec"

# alternative to "rails" command to use templates
function railsapp {
  template=$1
  appname=$2
  shift 2
  rails $appname -m http://github.com/ryanb/rails-templates/raw/master/$template.rb $@
}

# Quicker cd
alias cg='cd /Library/Ruby/Gems/1.8/gems/'
function cr() {
 cd ~/repos/$*
}
