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

{
    # X Settings
    /usr/bin/xmodmap /home/jpablobr/.Xmodmap  &
    /usr/bin/xset -b & # not beeps!
    /usr/bin/xset r rate 200 50
    /usr/bin/setxkbmap -option "ctrl:nocaps"  &
    /usr/bin/syndaemon -t -k -i 2 -d &
    /usr/bin/synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2
    /usr/bin/xscreensaver -no-splash &
    /usr/bin/xbindkeys

    # Defaults Apps
    # Start terminal emulation daemon
    /usr/bin/urxvtd -q -o -f &
    /home/jpablobr/.private/bin/mount-toshiba.sh &
    /home/jpablobr/.private/bin/start-dropbox.sh &
    /home/jpablobr/.private/bin/start-chrome.sh &
    sudo /usr/sbin/NetworkManager&>> $public_nw_log &
    /usr/bin/nm-applet --sm-disable &
    sudo /usr/bin/updatedb &

} &>>/tmp/init.log # tmp but append! w/e

# while true; do /usr/bin/ck-launch-session dwm
while true; do dwm
	xmessage 'insert coin to continue' \
        -buttons 'Insert Coin:0,Game Over' \
	- default 'Insert Coin' -timeout -30 \
        -center || break
done
