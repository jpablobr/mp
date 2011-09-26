#!/usr/bin/env bash

set -e

: ${HOME=~}
app=`pwd | xargs basename`
templates="$HOME/.templates"
exe=$(basename $0)

print-help(){
    tput setaf 3; echo "$1"; tput op
}

print-info(){
    tput setaf 2; echo "$1"; tput op
}

print-section(){
    tput setaf 5; echo ''; echo "### $1"; echo ''; tput op
}

check-file(){
    local file="$1"
    print-section "Checking for $file"
    if [[ -f $file ]]; then
        print-info "$file already exists:"
        cat $file
        echo ''
    else
        print-info "Creating new $file"
        cat $templates/ruby/$file
        cat $templates/ruby/$file |
        sed s:APP:$app:g |
        cat > $file
    fi
}

routes-file(){
    test ! -f routes.txt &&
    bundle exec rake routes > routes.txt
}

run-install-bundler(){
    print-section "Running and installing bundler."
    gem install bundler
    bundle install
    echo ''
}

run-file-commands(){
    print-section "Running the file checker."
    check-file 'config/database.yml'
    check-file '.rvmrc'
    echo ''
}

run-db-setup(){
    print-section "db:create:all."
    bundle exec rake db:create:all --trace
    print-section "db:migrate."
    bundle exec rake db:migrate --trace
    print-section "db:test:prepare."
    bundle exec rake db:test:prepare --trace
    echo ''
}

run(){
    print-section "Running the whole setup:"
    run-install-bundler
    print-section "Running routes-file setup:"
    routes-file
    print-section "Running DB setup:"
    run-db-setup
    bundle exec rails s
    echo ''
}

print-help(){
    tput setaf 2
	  cat <<- -EOF-
Usage: $exe [<options>]
$(tput setaf 6)$ $exe [] or [h]$(tput setaf 2)
This help.
$(tput setaf 6)$ $exe [i] $(tput setaf 2)
All of the default commands such as 'gem install bundler'
$(tput setaf 6)$ $exe [f]$(tput setaf 2)
File related commands
$(tput setaf 6)$ $exe [d]$(tput setaf 2)
Database related commands
-EOF-
tput op
}

if [[ "$1" == "h" ]]; then
    print-help
elif [[ "$#" == 0 ]]; then
    print-help
elif [[ "$1" == "i" ]]; then
    run
elif [[ "$1" == "d" ]]; then
    run-db-setup
elif [[ "$1" == "f" ]]; then
    run-file-commands
elif [[ "$1" == "r" ]]; then
    routes-file
fi

exit 0