#!/bin/sh

# notification
/usr/local/libexec/notification-daemon &

xmodmap ~/.xmodmap &
xrdb -load ~/.Xresources &
xrdb -load ~/.Xdefaults &
source ~/.bashrc &

/usr/bin/setxkbmap -option "ctrl:nocaps" &
/usr/local/libexec/notification-daemon &
urxvt &
~/bin/sh/focus -a 5 &

# applications
