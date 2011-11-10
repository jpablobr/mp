#!/bin/sh

# open your theme, otherwise it's ugly
gnome-settings-daemon &

# open screensaver
gnome-screensaver &
# Open Voume manager
gnome-volume-manager

# open power manager
gnome-power-manager &

# open net work manager
nm-applet &

#open auto update
update-notifier &

# notification
/usr/local/libexec/notification-daemon &
~/bin/sh/focus -a 5 &

# Styles
xmodmap ~/.Xmodmap &
xrdb -load ~/.Xresources &
xrdb -load ~/.Xdefaults &
/usr/bin/setxkbmap -option "ctrl:nocaps" &

# Meh, why not...
cd ~/bin/sh/conky/
conky -c ./conkydate &
conky -c ./conkyhr &
conky -c ./conkymin &
conky -c ./conkystats &

# Environments
source ~/.bashrc &

# Applications
/usr/local/libexec/notification-daemon &
urxvt &

pkill metacity; exec ck-launch-session awesome &
