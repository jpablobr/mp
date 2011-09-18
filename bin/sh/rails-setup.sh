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

run(){
    print-section "Running the basics."
    bundle update
    print-section "Running the db:create:all."
    bundle exec rake db:create:all --trace
    print-section "Running db:migrate."
    bundle exec rake db:migrate --trace
    print-section "Running db:test:prepare."
    bundle exec rake db:test:prepare --trace
    print-section "Running routes-file()."
    routes-file
    bundle exec rails s
    echo ''
}

if [[ "$1" == "h" ]]; then
tput setaf 2
	  cat <<- -EOF-
Usage: $exe [<options>]
$ $exe h
This help.
$ $exe i
will run all of the default commands such as 'gem install bundler'
$ $exe f
will run file related commands
$ $exe or with [s]
Will run commands without 'gem install bundler'
-EOF-
tput op
elif [[ "$#" == 0 ]]; then
    run-file-commands
    run
elif [[ "$1" == "i" ]]; then
    run-file-commands
    run-bundle-install
elif [[ "$1" == "s" ]]; then
    run
elif [[ "$1" == "f" ]]; then
    run-file-commands
fi

exit 0