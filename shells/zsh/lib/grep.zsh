#
# Color grep results
# Examples: http://rubyurl.com/ZXv
#
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'

function killnamed () {
    ps ax | grep $1 | cut -d ' ' -f 2 | xargs kill
}

function gprocess() {
  ps -ef | grep -in $1 | grep -v grep
}