# Prompt colors
_txt_col="\e[00m"     # Std text (white)
_bld_col="\e[1;37m"   # Bold text (white)
_wrn_col="\e[1;31m"   # Warning
_sep_col="\e[2;32m"   # Separators
_usr_col="\e[1;32m"   # Username
_cwd_col=$_txt_col    # Current directory
_hst_col="\e[0;32m"   # Host
_env_col="\e[0;36m"   # Prompt environment
_git_col="\e[1;36m"   # Git branch
_chr_col=$_txt_col    # Prompt char

# Returns the current git branch (returns nothing if not a git repository)
parse_git_branch() {
  \git branch 2> /dev/null | sed "s/^\* \([^ ]*\)/\1/;tm;d;:m"
}

parse_git_dirty() {
  [ -n "$(\git status --short 2> /dev/null)" ] && echo "±"
}

# Test whether file exists in current or parent directories
find_in_cwd_or_parent() {
  local slashes=${PWD//[^\/]/}; local directory=$PWD;
  for (( n=${#slashes}; n>0; --n )); do
    test -e $directory/$1 && echo "$directory/$1" && return 0
    directory=$directory/..
  done
  return 1
}

# Returns the Travis CI status for a given branch, default 'master'
parse_travis_status() {
  local branch="$1"
  if [ -z "$branch" ]; then branch="master"; fi

  local stat_file=$(find_in_cwd_or_parent ".travis_status~")
  if [ -e "$stat_file" ]; then
    case "$(grep -m 1 "^$branch " "$stat_file")" in
    *passed)  echo "\[\e[01;32m\]✔ ";; # green
    *failed)  echo "\[\e[01;31m\]✘ ";; # red
    *running) echo "\[\e[01;33m\]⁇ ";; # yellow
    esac
  fi
}

# When developing gems ($GEM_DEV is exported), display a hammer and pick
parse_gem_development() {
  if env | grep -q "^GEM_DEV="; then echo "\[\e[0;33m\]⚒ "; fi
}

# Set the prompt string (PS1)
# Looks like this:
#     user@computer ~/src/config [master]$

# (Prompt strings need '\['s around colors.)
set_ps1() {
  local user_str="\[$_usr_col\]\[$_sep_col\]\[$_hst_col\]\[$_txt_col\]"
  local dir_str="\[$_cwd_col\]\W"
  local git_branch=`parse_git_branch`
  local git_dirty=`parse_git_dirty`
  local trav_str=`parse_travis_status "$git_branch"`

  git_str="\[$_git_col\]$git_branch\[$_wrn_col\]$git_dirty"
  # Git repo & ruby version
  if [ -n "$git_branch" ]; then
    env_str="\[$_env_col\][$git_str\[$_env_col\]]"
  else
    unset env_str
  fi

  # < username >@< hostname > < current directory > < ci status > [< git branch >]
  PS1="\u@\h$user_str $dir_str $trav_str$env_str\[$_chr_col\]\`e=\$?;[ ! \$e = 0 ] && echo \[\e[31m\]\$e\[\e[0m\]\`\$ \[$_txt_col\]"
}

export PROMPT_COMMAND=set_ps1

# Custom Xterm/RXVT Title
case "$TERM" in
    xterm*|rxvt*)
        autoreload_prompt_command+='echo -ne "\e]0; ${PWD/$HOME/~}\007";'
        ;;
    *)
        ;;
esac
