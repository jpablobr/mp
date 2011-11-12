#!/usr/bin/env bash

# echo 'SSH/GPG agent'
# eval `gnome-keyring-daemon`

echo 'opne gnome-settings-deamon'
gnome-settings-daemon &

echo 'open screensaver'
gnome-screensaver &

echo 'Open Voume manager'
gnome-sound-applet &
# gnome 2
# gnome-volume-control-applet &

echo 'open power manager'
gnome-power-manager &

echo 'open net work manager'
nm-applet &

echo 'open auto update'
update-notifier &

echo 'notification setup'
/usr/local/libexec/notification-daemon &

echo 'Styles setup; xmodmap and Xresources'
xmodmap /home/jpablobr/.Xmodmap &
xrdb -load /home/jpablobr/.Xresources &
xrdb -load /home/jpablobr/.Xdefaults &
/usr/bin/setxkbmap -option "ctrl:nocaps" &
gsettings set  org.gnome.settings-daemon.plugins.background active false
# gconftool-2 --type bool --set /apps/gnome_settings_daemon/plugins/background/active False

echo 'source bashrc'
source ~/.bashrc &

# echo 'Conky stuff'
# cd /home/jpablobr/bin/sh/conky/
# conky -c ./conkydate &
# conky -c ./conkyhr &
# conky -c ./conkymin &
# conky -c ./conkystats &
# cd

# Applications
echo 'Dropbox'
dropbox start &
urxvt &

echo 'exec focus'
/home/jpablobr/bin/sh/focus -a 5 &

# exec /usr/bin/awesome