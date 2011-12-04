#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

public_nw_log='/var/log/jpablobr/public_nw.log'

eval `gpg-agent --daemon` &&
trap 'killall gpg-agent' EXIT

# Dbus session
test -z "$DBUS_SESSION_BUS_ADDRESS" &&
eval `dbus-launch --sh-syntax --exit-with-session`

# Wait for extra configurations such as calling gnome-session
/usr/bin/ck-launch-session awesome & wmpid=$!

    # Gnome GTK Settings
    /usr/lib/gnome-settings-daemon/gnome-settings-daemon &

    /usr/bin/gconftool-2 \
        --type bool \
        --set /apps/nautilus/preferences/show_desktop False &
     /usr/bin/gconftool-2 \
        --type string \
        --set /desktop/gnome/session/required_components/windowmanager metacity &
    /usr/bin/gconftool-2 \
        --type String \
        --set /desktop/gnome/url-handlers/org-protocol/command '/usr/bin/emacsclient %s' &
    /usr/bin/gconftool-2 \
        --type Boolean true \
        --set /desktop/gnome/url-handlers/org-protocol/enabled &

    /usr/bin/gsettings set org.gnome.gnome-panel.layout toplevel-id-list [] &

    # Gnome Apps
    sudo /usr/sbin/NetworkManager&>> $public_nw_log &
    /usr/bin/nm-applet --sm-disable &
    /usr/bin/gnome-sound-applet &

    # X Settings
    /usr/bin/xmodmap /home/jpablobr/.Xmodmap  &
    /usr/bin/xrdb -load /home/jpablobr/.Xdefaults &
    /usr/bin/xset -b & # not beeps!
    /usr/bin/setxkbmap -option "ctrl:nocaps"  &
    /usr/bin/syndaemon -t -k -i 2 -d &
    /usr/bin/synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2

    # Defaults Apps
    XAUTHORITY=~/.Xauthority emacs -l ~/.emacs.d/inits/jpablobr-init.el --daemon &
    /home/jpablobr/.private/bin/start-dropbox.sh &
    /home/jpablobr/.private/bin/mount-toshiba.sh &
    /usr/bin/urxvt -e $SHELL /home/jpablobr/.tmuxinator/jpablobr.tmux &
    /home/jpablobr/bin/sh/focus -a 5  &
    /usr/bin/google-chrome &
    /usr/bin/rhythmbox &
    sudo /usr/bin/updatedb &

wait $wmpid
