# Aliases
alias g='git'
alias gst='git status'
alias gup='git fetch && git rebase'
alias gp='git push'
alias gd='git diff | emacs'
alias gdv='git diff -w "$@" | vim -R -'
alias gb='git branch'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias ungit="find . -name '.git' -exec rm -rf {} \;"
alias gba='git branch -a'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gck='git checkout'

# Commit pending changes and quote all args as message
function gg() {
    git commit -v -a -m "$*"
}
alias gco='git checkout'
alias gdm='git diff master'
alias gl='git pull'
alias gnp="git-notpushed"
alias gst='git status'
alias gt='git status'
alias eg='open /Applications/Emacs.app/ .git/config'

# Git clone from GitHub
function gch() {
  git clone git://github.com/$USER/$1.git
}

# Setup a tracking branch from [remote] [branch_name]
function gbt() {
  git branch --track $2 $1/$2 && git checkout $2
}
# Quickly clobber a file and checkout
function grf() {
  rm $1
  git checkout $1
}

# Call from inside an initialized Git repo, with the name of the repo.
function new-git() {
  ssh git@example.com "mkdir $1.git && cd $1.git && git --bare init"
  git remote add origin git@example.com:$1.git
  git push origin master
  git config branch.master.remote origin
  git config branch.master.merge refs/heads/master
  git config push.default current
}

parse_git_dirty () {
  if [[ $((git status 2> /dev/null) | tail -n1) != "nothing to commit (working directory clean)" ]]; then
    echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
  else
    echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
}

#
# Will return the current branch name
# Usage example: git pull origin $(current_branch)
#
function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}

# get the name of the branch we are on
function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}