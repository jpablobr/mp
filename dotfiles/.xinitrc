#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

startups_log='/var/log/jpablobr/jp-startups.log'
private_nw_log='/var/log/jpablobr/private_nw.log'
public_nw_log='/var/log/jpablobr/public_nw.log'

# Encription
eval `gpg-agent --daemon` &&
trap 'killall gpg-agent' EXIT

# Dbus session
test -z "$DBUS_SESSION_BUS_ADDRESS" &&
eval `dbus-launch --sh-syntax --exit-with-session`

# Wait for extra configurations such as calling gnome-session
ck-launch-session awesome & wmpid=$!

gnome-session &

xmodmap /home/jpablobr/.Xmodmap  &
xrdb -load /home/jpablobr/.Xresources  &
xrdb -load /home/jpablobr/.Xdefaults &
# xscreensaver &
/usr/bin/setxkbmap -option "ctrl:nocaps"  &
gsettings set org.gnome.gnome-panel.layout toplevel-id-list []
gconftool-2 --type bool --set /apps/nautilus/preferences/show_desktop False
gconftool-2 --type string --set /desktop/gnome/session/required_components/windowmanager awesome
xset -b &

# touchpad
# http://wiki.archlinux.org/index.php/Touchpad_Synaptics
syndaemon -t -k -i 2 -d &
synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2

# Dropbox
sudo sysctl fs.inotify.max_user_watches=1000000 &
dropboxd  &

/home/jpablobr/bin/sh/focus -a 5  &

# Window manager log
# urxvt -e tail -F /var/log/Xorg.0.log &

# Tmux
urxvt -e $SHELL ~/.tmuxinator/jpablobr.tmux &

# /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
sudo NetworkManager&>> $public_nw_log &
sudo nm-applet --sm-disable &>> $public_nw_log &

wait $wmpid
