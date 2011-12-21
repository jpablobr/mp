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

/usr/bin/xrdb -load /home/jpablobr/.Xdefaults &&

# Wait for extra configurations such as calling gnome-session
/usr/bin/ck-launch-session awesome & wmpid=$!

{
    (   # Gnome GTK Settings.
        # Most of this stuff relies on gnome-settings already
        # being set, wait for it on a sub-shell and continue
        # with the rest of exit 0.
        /usr/lib/gnome-settings-daemon/gnome-settings-daemon &&

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
            --type Boolean \
            --set /desktop/gnome/url-handlers/org-protocol/enabled true &
        /usr/bin/gconftool-2 \
            --type boolean \
            --set /apps/gnome_settings_daemon/screensaver/start_screensaver false

        # Apps
        /usr/bin/gnome-sound-applet &
    ) &

    # X Settings
    /usr/bin/xmodmap /home/jpablobr/.Xmodmap  &
    /usr/bin/xset -b & # not beeps!
    /usr/bin/setxkbmap -option "ctrl:nocaps"  &
    /usr/bin/syndaemon -t -k -i 2 -d &
    /usr/bin/synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2
    /usr/bin/xscreensaver -no-splash &
    /usr/bin/xbindkeys

    # Defaults Apps
    /home/jpablobr/.private/bin/mount-toshiba.sh &
    /home/jpablobr/.private/bin/start-dropbox.sh &
    /home/jpablobr/.private/bin/start-chrome.sh &
    /usr/bin/urxvt &
    # /usr/bin/urxvt -e $SHELL /home/jpablobr/.tmuxinator/jpablobr.tmux &
    XAUTHORITY=~/.Xauthority /usr/local/bin/emacs-24.0.92 -l ~/.emacs.d/inits/jpablobr-init.el --daemon &
    /home/jpablobr/bin/sh/focus -a 5  &
    sudo /usr/sbin/NetworkManager&>> $public_nw_log &
    /usr/bin/nm-applet --sm-disable &
    sudo /usr/bin/updatedb &

} &>>/tmp/init.log # tmp but append! w/e

wait $wmpid
