#
# Color grep results
# Examples: http://rubyurl.com/ZXv
#
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'

function gprocess() {
  ps -ef | grep -in $1 | grep -v grep
}