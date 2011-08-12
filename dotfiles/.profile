# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

YSRESOURCES=/etc/X11/Xresources
USRRESOURCES=$HOME/.Xresources
