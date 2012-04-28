#!/usr/bin/sh
# Common aliases
alias o='mimeopen'
alias h='history | grep -i'
alias i='pry'
alias l='less'
alias j='jobs -l'
alias r='fc -s'
alias rl='. ~/.bashrc'
alias sudo='sudo ' # What is this I don't even.
alias chx='chmod +x'
alias ct='cheat_fu'
alias ctr='cd ~/.cheats_fu_sheets && ronn -r *.1.ronn && cd -'
alias mkd='mkdir -pv'
alias sjp='urxvt -e $SHELL ~/.tmuxinator/jpablobr.tmux &'
alias merge_xresources='xrdb -merge ~/.Xresources'
alias load_xresources='xrdb -load ~/.Xresources'
alias hup='kill -HUP \!*'
alias more='less'
alias zombies='ps al | grep " Z "'
alias cpf='cp -frpv'
alias tmux='tmux -2'
alias ag='alias | egrep'
alias export_current_dir='export PATH="$PATH:`pwd`"'
alias fcl='fc -l 1'
alias hg='history | egrep'
alias whereami='echo "$( hostname --fqdn ) ($(hostname -i)):$( pwd )"'
alias gp='~/bin/g -p'
alias du1='du -h --max-depth=1'
alias fs='ttycoke cat_focus.sh'
alias fe='emacsclient -c ~/.private/notes/focus.md'
alias spsql='sudo /etc/rc.d/postgresql start'
alias mply='mplayer -vo x11 -zoom -framedrop'
alias dask='/usr/bin/setxkbmap -option "altwin:ctrl_win,ctrl:nocaps,altwin:alt_super_win"'
alias pidipsc='sudo lsof -i -s -P'
alias psg='ps axjf --cols 10000 | egrep'
# Pids IPs
alias pidips='sudo lsof -iTCP -sTCP:LISTEN -P'
alias ansi-chart='for f in {30..37};do for b in {40..47};do printf "\e[%dm \e[%dm%d;%d \e[0m" $b $f $f $b;done;echo;done'
alias hgrep='history | grep -i'
op(){ "$1" >/dev/null 2>&1 & }
alias sloc='cloc --by-file-by-lang --exclude-dir .git'
alias curlr='curl -C - -L -O'
alias sup_os='export | egrep'
alias grg='greg.rb'
alias grgw="ls *.flv | grep -v -e 'blog*' -e 'gcb' | umplayer"
alias mysqlsocket='mysqladmin variables | grep socket'
alias smysql='sudo rc.d start mysqld'
alias lsdaemons='ls -la /run/daemons/'
alias ralsa='sudo rc.d restart alsa'
alias flv2mp4='ls *.flv | xargs du -h | sort -n | cut -f 2 | xargs mp4ize'
alias cb='~/bin/simple_clipboard'
alias list_biggest_in_tree='find . -ls | sort -n -k 7 | tail -5'
alias broken_links='find . -type l | (while read FN ; do test -e "$FN" || ls -ld "$FN"; done)'
alias symlinks='find . -type l'
alias remove_symlinks='for f in $(find . -type l); do rm $f; done'
alias gst=gs
alias gtg='gt-l | egrep '
# moving in dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

for mod in x w r; do
  alias -- "+$mod"="chmod +$mod"
  alias -- "-$mod"="chmod -- -$mod"
done

# Aliases for scripts in ~/bin
# ----------------------------
alias cb="simple_clipboard"
# Copy contents of a file
alias cbf="simple_clipboard <"
# Copy SSH public key
alias cbs="simple_clipboard < ~/.ssh/id_rsa.pub"
# Copy current working directory
alias cbd="pwd | simple_clipboard"

alias eg='env | egrep -i '
alias pg='ps aux | egrep'
alias fcm='compgen -abck | egrep -i'
alias rmf='rm -frv'
alias gnome_remove_panels='gsettings set org.gnome.gnome-panel.layout toplevel-id-list []'
alias screen_lock='xscreensaver-command -lock'
alias wget_r='wget -rkp -l3 -np -nH --cut-dirs=1'
alias mvpas='mv file $OLDPWD/'
alias reboot="sudo shutdown -r now"
alias shutdown="sudo shutdown -h now"
alias gemfileg='cat ./Gemfile.lock | grep'
alias plr='~/bin/playr/playr -s'

# - Ruby
alias bl='bundle --local || bundle'
alias gemiglobal='rvm use default@global && gem install'
alias gempurge='gem list | cut -d” ” -f1 | xargs gem uninstall -aIx'
alias rdl='ruby -Ilib'
alias rpr='pry -Ilib -r'
alias rubyencoding="sed '1i\# -*- encoding: utf-8 -*-' -i "
alias rubyencodingr="git ls-files '*.rb' | xargs sed '1i\# -*- encoding: utf-8 -*-' -i"
rvmuse () {
    [ -n "$1" ] && echo "rvm use $1" > .rvmrc;
}
# - Rails
alias rradbm='rake db:migrate && rake db:test:prepare'
alias rrroutes='bundle exec rake routes > routes.txt'
alias rrlog='tail -fn0 ./log/*.log'
alias rrcp='pry -r ./config/environment'
alias rrc='./script/rails console'
alias rrs='./script/rails server'
alias rrsl='rrs >& log/server-`date +%Y-%m-%d-%H:%M`.log'
alias rru='unicorn_rails'
alias rrr='cat routes.txt | while read l; do echo $l; done'
alias rrrg='bundle exec rake routes > routes.txt'

# ---------------------------------------------------------
# Alias management (helper functions for ~/.bash_aliases)
# ---------------------------------------------------------

# Adds an alias to ~/.bash_aliases.
# ------------------------------------------------
add_alias() {
  if [ -n "$2" ]; then
    touch ~/.bash_aliases
    echo "alias $1=\"$2\"" >> ~/.bash_aliases
    source ~/.bashrc
  else
    echo "Usage: add_alias <alias> <command>"
  fi
}
# Adds a change directory alias to ~/.bash_aliases.
# Use '.' for current working directory.
# Changes directory, then lists directory contents.
# ------------------------------------------------
add_dir_alias() {
  if [ -n "$1" ] && [ -n "$2" ]; then
    path=`dirname $2/.`   # Fetches absolute path.
    touch ~/.bash_aliases
    echo "alias $1=\"cd $path; ll\"" >> ~/.bash_aliases
    source ~/.bashrc
  else
    echo "Usage: add_dir_alias <alias> <path>"
  fi
}
# Remove an alias
# ------------------------------------------------
rm_alias() {
  if [ -n "$1" ]; then
    touch ~/.bash_aliases
    grep -Ev "alias $1=" ~/.bash_aliases > ~/.bash_aliases.tmp
    mv ~/.bash_aliases.tmp ~/.bash_aliases
    unalias $1
    source ~/.bashrc
  else
    echo "Usage: rm_alias <alias>"
  fi
}
