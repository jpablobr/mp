# if [ "$STARTX" == "1" ];then
# unset STARTX ; startx &>/dev/null
# exit 0
# fi

[ -f ~/.bashrc ] && . ~/.bashrc

YSRESOURCES=/etc/X11/Xresources
USRRESOURCES=$HOME/.Xresources

#exec /bin/bash --login
