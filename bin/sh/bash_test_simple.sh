#!/bin/bash
set -u    # Error if unitialized variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#: Description   : A very simple testing framework for bash.
#:               : Features hooks, formatted output and 
#:               : summaries for tests arranged into test
#:               : suites. 
#:
#:               : Simple, extensible and somewhat 
#:               : fun.
#:
#: Author        : Bryan Smith
#: Contact       : bryanesmith@gmail.com
#: Version       : Beta 1.0
#: Created       : Sat Apr 9 2011
#: Last modified : Sun Apr 10 2011
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

spit() {
  for (( n=1; n<=${1}; ++n ))
  do
    printf "%s" "$2"
  done 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
init_suite() {
  PASSED=0
  FAILED=0
  WARNINGS=0
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
readonly TITLE_MAX=40
readonly GLITTER_LEN=0
readonly HEADER_LEN=$(( $GLITTER_LEN * 2 + 8 + $TITLE_MAX ))
readonly HEAVY_CHAR='='
readonly LIGHT_CHAR='-'
readonly HEAVY_GLITTER=$( spit $GLITTER_LEN $HEAVY_CHAR )
readonly LIGHT_GLITTER=$( spit $GLITTER_LEN $LIGHT_CHAR )
readonly HEAVY_BAR=$( spit $HEADER_LEN $HEAVY_CHAR )
readonly LIGHT_BAR=$( spit $HEADER_LEN $LIGHT_CHAR )
readonly TABLE_NUM_MAX=10
readonly TABLE_STR_MAX=10
readonly TABLE_LEN=$(( 3 + 6 + $TABLE_STR_MAX + $TABLE_NUM_MAX ))
readonly TABLE_MARGIN_LEN=$(( ( $HEADER_LEN - TABLE_LEN ) / 2 ))
readonly TABLE_MARGIN=$( spit $TABLE_MARGIN_LEN ' ' )

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
readonly WARNING_TEMP='.warnings'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
suite() {
  printf "\n%s\n" "$HEAVY_BAR"
  printf " Starting suite: %s\n" "$1"
  printf "%s\n\n" "$HEAVY_BAR"
  init_suite
  when_suite_starts
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
table_top() {
  printf "%s%s%s%s%s" "$TABLE_MARGIN" '/' $( spit $(( $TABLE_LEN - 2 )) '=' ) '\' "$TABLE_MARGIN"
  printf "\n"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
table_bottom() {
  printf "%s%s%s%s%s" "$TABLE_MARGIN" '\' $( spit $(( $TABLE_LEN - 2 )) '=' ) '/' "$TABLE_MARGIN"
  printf "\n"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
table_row() {
  printf "%s|  %-${TABLE_STR_MAX}.${TABLE_STR_MAX}s | %${TABLE_NUM_MAX}d  |%s\n" "$TABLE_MARGIN" "$1" "$2" "$TABLE_MARGIN"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
end() {
  printf "Finished suite.\n"

  when_suite_ends

  table_top
  table_row Tests $(( $PASSED + $FAILED ))
  table_row Passed $PASSED
  table_row Failed $FAILED
  table_row Warnings $WARNINGS
  table_bottom
  printf "\n"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
passed() {
  PASSED=$(( $PASSED + 1)) 
  printf "%s\n" PASSED
  when_test_passes
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
failed() {
  FAILED=$(( $FAILED + 1 ))
  printf "%s (Exit code: %d)\n" FAILED $1
  when_test_fails
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
run() {
  printf "%s\n" $LIGHT_BAR
  printf "%s Test: %${TITLE_MAX}.${TITLE_MAX}s %s\n" "$LIGHT_GLITTER" $1 "$LIGHT_GLITTER"
  printf "%s\n" $LIGHT_BAR

  when_test_starts

  Output=$( $1 )
  Exit=$?
  IFS=$'\n'
  printf "  > %s\n" $Output
  IFS=' '
  printf "\n"
  case $Exit in
    '0') passed ;;
    *) failed $Exit
  esac

  printf "\n"

  update_warning_count_from_child 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
warn() {
  Output=$( $1 )
  Exit=$?
  printf "\n%s" "$Output"
  
  if [ $Exit -ne 0 ]; then
    printf "WARNING: %s (exit code: %d)\n" "$2" $Exit
    increment_warning_count
    when_warns
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
increment_warning_count() {
  WARNINGS=$(( $WARNINGS + 1 ))
  echo $WARNINGS > $WARNING_TEMP
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
update_warning_count_from_child() {
  if [ -e $WARNING_TEMP ]; then
    read WARNINGS < $WARNING_TEMP
    rm $WARNING_TEMP
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
assert() {
  Output=$( $1 )
  Exit=$?
  printf "\n%s" "$Output"
  
  if [ $Exit -ne 0 ]; then
    error "$Exit" "$2"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
error() {
  printf "ERROR: %s (exit code: %d)\n" "$2" $Exit  
  exit $Exit
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
trace() {
  printf "DEBUG: %s\n" "$1"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
nothing() {
  printf ''
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_suite_starts() {
  nothing
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_suite_ends() {
  nothing
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_test_starts() {
  nothing 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_test_fails() {
  nothing 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_test_passes() {
  nothing 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
when_warns() {
  nothing
}

