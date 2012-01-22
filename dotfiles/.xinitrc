#!/bin/sh

# execute the rest of this file under the ConsoleKit environment
sed -n '/^sed/,$p' "$0" | sed 1d | /usr/bin/ck-launch-session sh -x; exit

eval `gpg-agent --daemon` &&
trap 'killall gpg-agent' EXIT

test -z "$DBUS_SESSION_BUS_ADDRESS" &&
eval `dbus-launch --sh-syntax --exit-with-session`

/usr/lib/notification-daemon-1.0/notification-daemon &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Disable Nautilus desktop
/usr/bin/gconftool-2 \
    --type bool      \
    --set /apps/nautilus/preferences/show_desktop False &

# Settings
/usr/bin/xset -b & # not beeps!
/usr/bin/xset r rate 200 50 &
/usr/bin/xrdb -load ~/.Xdefaults &
/usr/bin/xmodmap ~/.Xmodmap  &
/usr/bin/setxkbmap -option "ctrl:nocaps"  &
/usr/bin/syndaemon -t -k -i 2 -d &
/usr/bin/synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2 &
/usr/bin/xscreensaver -no-splash &
/usr/bin/xbindkeys &
/usr/bin/urxvtd -q -o -f &
# /usr/bin/sonata --hidden &
sudo /usr/bin/updatedb &

# Scripts
~/.private/bin/network/network-setup.sh -m &
~/.private/bin/start/start-mpd.sh &
~/.private/bin/start/start-chromium.sh &
~/.private/bin/start/start-dropbox.sh &

~/bin/term -name emacs

while true; do wmii
    xmessage 'INSERT COIN TO CONTINUE'     \
        -buttons 'Insert Coin:0,Game Over' \
        -default 'Insert Coin' -timeout 5  \
        -center || break
done
