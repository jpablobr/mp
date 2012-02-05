#!/bin/sh
# Common aliases
alias o='mimeopen'
alias h='history | grep -i'
alias i='pry'
alias l='less'
alias j='jobs -l'
alias g='git'
alias r='fc -s'
alias rl='. ~/.bashrc'
alias sudo='sudo ' # What is this I don't even.
alias chx='chmod +x'
alias ct='cheat_fu'
alias ctr='cd ~/.cheats_fu_sheets && ronn -r *.1.ronn && cd -'
alias r*='rm -frv *'
alias mkd='mkdir -pv'
alias sjp='urxvt -e $SHELL ~/.tmuxinator/jpablobr.tmux &'
alias merge_xresources='xrdb -merge ~/.Xresources'
alias load_xresources='xrdb -load ~/.Xresources'
alias hup='kill -HUP \!*'
alias more='less'
alias zombies='ps al | grep " Z "'
alias cpf='cp -frpv'
alias fn='find . -name'
alias tmux='tmux -2'
alias ag='alias | grep '
alias export_current_dir='export PATH="$PATH:`pwd`"'
alias history='fc -l 1'
alias hi='history | tail -20'
alias whereami='echo "$( hostname --fqdn ) ($(hostname -i)):$( pwd )"'
alias gst='g status -sbu'
alias gs='g stash'
alias du1='du -h --max-depth=1'
alias fs='ttycoke cat_focus.sh'
alias fe='emacsclient -c ~/.private/notes/focus.md'

# Pids IPs
alias pidips='sudo lsof -iTCP -sTCP:LISTEN -P'
alias ansi-chart='for f in {30..37};do for b in {40..47};do printf "\e[%dm \e[%dm%d;%d \e[0m" $b $f $f $b;done;echo;done'
alias hgrep='history | grep -i'
op(){ "$1" >/dev/null 2>&1 & }
alias sloc='cloc --by-file-by-lang --exclude-dir .git'
alias curlr='curl -C - -L -O'
alias sup_os='export | grep -i'

# aliases
alias list_biggest_in_tree='find . -ls | sort -n -k 7 | tail -5'
alias broken_links='find . -type l | (while read FN ; do test -e "$FN" || ls -ld "$FN"; done)'
alias symlinks='find . -type l'
alias remove_symlinks='for f in $(find . -type l); do rm $f; done'

# moving in dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

aappd(){
    local alias_cmd=($@)
    local name=$(echo ${alias_cmd[0]})
    unset alias_cmd[0]
    echo "alias ${name}='${alias_cmd[*]}'" >> ~/.mp/dotfiles/.bash.d/aliases.bash
    grep -i "$1"  ~/.mp/dotfiles/.bash.d/aliases.bash
    exit 0
}

alias eg='env | grep -i '
alias pg='ps aux | grep'
alias fcm='compgen -abck | grep -i'
alias rmf='rm -frv'
alias gnome_remove_panels='gsettings set org.gnome.gnome-panel.layout toplevel-id-list []'
alias screen_lock='xscreensaver-command -lock'
alias wget_r='wget -rkp -l3 -np -nH --cut-dirs=1'
alias mvpas='mv file $OLDPWD/'
alias reboot="sudo shutdown -r now"
alias shutdown="sudo shutdown -h now"
