#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

public_nw_log='/var/log/jpablobr/public_nw.log'

# Wait for extra configurations such as calling gnome-session
ck-launch-session awesome & wmpid=$!
    gnome-session &
    xmodmap /home/jpablobr/.Xmodmap  &
    xrdb -load /home/jpablobr/.Xdefaults &
    /usr/bin/setxkbmap -option "ctrl:nocaps"  &
    gsettings set org.gnome.gnome-panel.layout toplevel-id-list [] &
    gconftool-2 \
        --type bool \
        --set /apps/nautilus/preferences/show_desktop False &
    gconftool-2 \
        --type string \
        --set /desktop/gnome/session/required_components/windowmanager awesome &
    xset -b & # not beeps!
    sudo updatedb &
    sudo sysctl fs.inotify.max_user_watches=1000000 &
    DISPLAY=:0.0 XAUTHORITY=~/.Xauthority \
        emacs -l ~/.emacs.d/inits/jpablobr-init.el --daemon &

    # touchpad
    # http://wiki.archlinux.org/index.php/Touchpad_Synaptics
    syndaemon -t -k -i 2 -d &
    synclient HorizTwoFingerScroll=1 TapButton2=3 TapButton3=2

    /home/jpablobr/bin/sh/focus -a 5  &

    sudo NetworkManager&>> $public_nw_log &
wait $wmpid
