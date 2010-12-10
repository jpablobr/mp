# Aliases
alias g='git'
alias gst='git status'
alias gup='git fetch && git rebase'
alias gp='git push'
alias gb='git branch'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias ungit="find . -name '.git' -exec rm -rf {} \;"
alias gba='git branch -a'
alias gca='git commit -v -a'
alias gc='git clone'
alias gi='git init && printf ".DS_Store\nThumbs.db\n" >> .gitignore && git add .gitignore'

# http://www.jukie.net/~bart/blog/pimping-out-git-log
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%an %cr)%Creset' --abbrev-commit --date=relative"
alias glp='gl -p'

alias gdv='git diff -w "$@" | vim -R -'
alias gd='git diff'
alias gds='git diff --cached'
alias gdh='git diff HEAD'

alias ga='git add'
alias gap='git add -p'
alias gco="git checkout"
alias gcop="git checkout -p"

alias gpr='git pull --rebase || (notify "pull failed" "Git" && false)'
alias gu='git push origin HEAD || (notify "push failed" "Git" && false)'
alias gpru='gp && rake && gu'
alias gri='git rebase -i origin/master^'
alias grc='git rebase --continue'

complete -o default -o nospace -F _git_branch gb

alias gitx='gitx --all'

ggc() {
  set -- `du -ks`
  before=$1
  git reflog expire --expire=1.minute refs/heads/master && git fsck --unreachable && git prune && git gc 
  set -- `du -ks`
  after=$1
  echo "Cleaned up $((before-after)) kb."
}

grb() {
  git push origin HEAD:refs/heads/$1
  git fetch origin &&
  git checkout -b $1 --track origin/$1
}

current_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

git_commits_ahead() {
  git status 2> /dev/null | grep ahead | sed -e 's/.*by \([0-9]\{1,\}\) commits\{0,1\}\./\1/'
}

# Roughly from git_completion
git_dirty_state() {
  local w
  w=''
  local g="$(__gitdir)"
  if [ -n "$g" ]; then
    git diff --no-ext-diff --quiet --exit-code || w="+"
    if git rev-parse --quiet --verify HEAD >/dev/null; then
      git diff-index --cached --quiet HEAD -- || w="+"
    fi
  fi
  echo -n $w
}

git_modifications() {
  wrap_unless_empty "`git_commits_ahead`" "`git_dirty_state`"
}
wrap_unless_empty() {
  if [ -n "$1" ] || [ -n "$2" ] || [ -n "$3" ] || [ -n "$4" ]; then
    echo -n "($1$2$3$4)"
  fi
}

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

# Git clone from GitHub
function gch() {
  git clone git://github.com/$1/$2.git
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