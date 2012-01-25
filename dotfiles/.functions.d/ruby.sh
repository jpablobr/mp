#!/bin/sh

# - Ruby
alias bl='bundle --local || bundle'
alias geminstallglobal='rvm use default@global && gem install'
alias gempurge='gem list | cut -d” ” -f1 | xargs gem uninstall -aIx'
alias rdl='ruby -Ilib'
alias rpr='pry -Ilib -r'
alias rubyencoding="sed '1i\# -*- encoding: utf-8 -*-' -i "
alias rubyencodingr="git ls-files '*.rb' | xargs sed '1i\# -*- encoding: utf-8 -*-' -i"

# - Rails
alias rradbm='rake db:migrate && rake db:test:prepare'
alias rrroutes='bundle exec rake routes > routes.txt'
alias rrlog='tail -fn0 ./log/*.log'
alias rrc='pry -r ./config/environment'
alias rrs='./script/rails s'
alias rrsl='rrs >& log/server-`date +%Y-%m-%d-%H:%M`.log'

rrsm() {
    ps aux | grep '[s]cript/rails s' | awk '{print $2}' | xargs pmap
}

rctagsg() {
    find $(echo $GEM_PATH | cut -d: -f1) -type f -name '*.rb' | ctags -e --verbose=yes -L -
}

rctagsp() {
    find . -type f -name '*.rb' | ctags -e --verbose=yes -L -
}
