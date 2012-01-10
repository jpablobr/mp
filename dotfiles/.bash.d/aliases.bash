#!/bin/bash
# Common aliases
alias sudo='sudo ' # What is this I don't even.
alias o='xdg-open'
alias h='history | grep -i'
alias more='less'
alias l='less'
alias chx='chmod +x'
alias k9="kill -9"
alias ct='cheat_fu'
alias ctr='cd ~/.cheats_fu_sheets && ronn -r *.1.ronn && cd -'
alias r*='rm -frv *'
alias mkd='mkdir -pv'
alias ..='cd ..'
alias g='git --no-pager'
alias gst='g status'
alias sjp='urxvt -e $SHELL ~/.tmuxinator/jpablobr.tmux &'
alias merge_xresources='xrdb -merge ~/.Xresources'
alias load_xresources='xrdb -load ~/.Xresources'
alias hup='kill -HUP \!*'
alias j='jobs -l'
alias zombies='ps al | grep " Z "'
alias cpf='cp -frpv'
alias fn='find . -name'
alias tmux='tmux -2'
alias ag='alias | grep '
alias export_current_dir='export PATH="$PATH:`pwd`"'
alias history='fc -l 1'
alias hi='history | tail -20'
alias r='fc -s'
alias whereami='echo "$( hostname --fqdn ) ($(hostname -i)):$( pwd )"'

# Pids IPs
alias pidips='sudo lsof -iTCP -sTCP:LISTEN -P'
alias du1='du -h --max-depth=1'

 # ANSI color chart
alias ansi-chart='for f in {30..37};do for b in {40..47};do printf "\e[%dm\e[%dm%d on %d\e[0m" $b $f $f $b;done;echo;done'
alias hgrep='history | grep -i'
op(){ "$1" >/dev/null 2>&1 & }
alias sloc='cloc --by-file-by-lang --exclude-dir .git'
alias curlr='curl -C - -L -O'
alias ubuntu-version='lsb_release -a'
alias g-log-gdm0="sudo less gdm/:0.log | grep EE"
alias sup_os='export | grep -i'

##############################################################################->
# - Ruby
alias rg='bundle exec rake -T | grep'
alias bl='bundle --local || bundle'
alias rctags-g="find $(echo $GEM_PATH | cut -d: -f1) -type f -name '*.rb' | ctags -e --verbose=yes -L -"
alias rctags-p="find . -type f -name '*.rb' | ctags -e --verbose=yes -L -"
# - Rails
alias rr-asl='rails s >& log/server-`date +%Y-%m-%d-%H:%M`.log'
alias rr-adbm='rake db:migrate && rake db:test:prepare'
alias rr-routes='bundle exec rake routes > routes.txt'
alias rr-log='tail -fn0 ./log/*.log /var/log/apache*/*log'
alias rrc='pry -r ./config/environment'

# - heroku
alias hi='heroku info'
alias hp="git push heroku master"
alias h-t='heroku logs --tail'

##############################################################################->
# Aliases directly appended from shell
#
aappd(){
    local alias_cmd=($@)
    local name=$(echo ${alias_cmd[0]})
    unset alias_cmd[0]
    echo "alias ${name}='${alias_cmd[*]}'" >> ~/.mp/dotfiles/.bash.d/aliases.bash
    grep -i "$1"  ~/.mp/dotfiles/.bash.d/aliases.bash
    exit 0
}

alias envg='env | grep -i '
alias rmf='rm -frv'
alias gnome_remove-panels='gsettings set org.gnome.gnome-panel.layout toplevel-id-list []'
alias gem_purge='gem list | cut -d” ” -f1 | xargs gem uninstall -aIx'
alias screen_lock='xscreensaver-command -lock'
alias wget_r='wget -rkp -l3 -np -nH --cut-dirs=1'
alias pg='ps aux | grep'
alias fcm='compgen -abck | grep -i '
alias mvpas='mv file $OLDPWD/'
alias reboot="sudo shutdown -r now"
alias shutdown="sudo shutdown -h now"
