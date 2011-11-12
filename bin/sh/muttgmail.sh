#!/bin/bash

 ########################################################################################
 #										      	#
 #	Mutt GMail (IMAP) Config script						      	#
 # ====================================================================================	#
 #										      	#
 #	Written by Xan Manning (http://xan-manning.co.uk)			      	#
 #										      	#
 # ====================================================================================	#
 # "THE BEER-&-COFFEE-WARE LICENSE" [ Revision 0 ]:				      	#
 # - Variation of the "BEER-WARE LICENSE" Rev 42.				      	#
 # <xan . manning at gmail.com> wrote this file. As long as you retain this notice 	#
 # you can do whatever you want with this stuff. If we meet some day, and you think	#
 # this stuff is worth it, you can buy me a beer or coffee in return. Xan Manning	#
 # ====================================================================================	#
 #											#
 #	A bash script that will install (Debian/Ubuntu)					#
 #	and configure Mutt with access to your GMail account. 				#
 #											#
 ########################################################################################

 # First we determine if Mutt is installed.
 clear
 echo "Mutt GMail (IMAP) Configuration"
 echo "Written by Xan Manning (xan-manning.co.uk)"
 echo ""

 echo "WARNING: This file will overwrite your Mutt config."
 read -p "Do you wish to continue? (Y/n)" REPLY
 [ "$REPLY" = "y" ] || exit 0 ;

 echo ""
 echo ""

hash sudo 2>&- || { echo >&2 "Sudo is required for installing Mutt if it is missing. If you do not wish to use automatic install use the argument --nosudo"; exit 1; }

if [ "$1" = "--nosudo" ] ; then
	echo "Not checking package managers..."
	TRASH=0
else
	# Are we using Advanced Packaging Tool?
	if type -p apt-get ; then
		hash mutt 2>&- || { echo >&2 "Mutt not found, installing..."; sudo apt-get install mutt; }
		TRASH=1
	elif type -p yum ; then
		# Or Yellowdog updater, modified?
		hash mutt 2>&- || { echo >&2 "Mutt not found, installing..."; sudo yum install mutt; }
		TRASH=0
	elif type -p pacman ; then
		# Are we using PacMan?
		hash mutt 2>&- || { echo >&2 "Mutt not found, installing..."; sudo pacman -S mutt; }
		TRASH=0
	else
		echo "Cannot find a supported package manager..."
		TRASH=0
	fi
fi

hash mutt 2>&- || { echo >&2 "Mutt could not be found! Quitting..."; exit 1; }

 # Blank .muttrc file!

 echo "" > ~/.muttrc

 # Now we get some details...

stty_orig=`stty -g`
NOPASS=0

echo ""

echo "Creating .muttrc file."
touch ~/.muttrc

echo "Securing .muttrc file."
chmod 0700 ~/.muttrc

if [ ! -d ~/.mutt ] ; then
	echo "Creating .mutt directory."
	mkdir ~/.mutt
fi
echo "Securing .mutt directory."
chmod 0700 ~/.mutt

if [ ! -d ~/.mutt/cache ] ; then
	echo "Creating Cache directory."
	mkdir ~/.mutt/cache
fi

echo ""
echo ""

echo "What is your real full name?: "

read realname

echo "set realname = '$realname'" > ~/.muttrc

echo ""
echo "What is your GMail address?: "

read from

echo "set from = '$from'" >> ~/.muttrc
echo "set imap_user = '$from'" >> ~/.muttrc

while [ $NOPASS != 1 ] ; do
	echo ""
	echo "What is your Password?: "

	stty -echo
	read passworda
	
	echo ""
	echo "Repeat: "

	read passwordb
	stty $stty_orig

	if [ "$passworda" != "$passwordb" ]; then
		echo "Passwords do not match!"
	else
		PASSWORD=$passworda
		NOPASS=1
	fi
done

echo "set imap_pass = '$PASSWORD'" >> ~/.muttrc

echo ""
echo ""
echo "Writing configuration..."

echo "set imap_keepalive = 900" >> ~/.muttrc
echo "set folder = 'imaps://imap.gmail.com:993'" >> ~/.muttrc
echo "set spoolfile = '+INBOX'" >> ~/.muttrc
echo "set postponed = '+[Gmail]/Drafts'" >> ~/.muttrc
if [ $TRASH == "1" ] ; then
	echo "set trash = 'imaps://imap.gmail.com/[Gmail]/Trash'" >> ~/.muttrc
fi
echo "set header_cache = '~/.mutt/cache/headers'" >> ~/.muttrc
echo "set message_cachedir = '~/.mutt/cache/bodies'" >> ~/.muttrc
echo "set certificate_file = '~/.mutt/certificates'" >> ~/.muttrc
echo "set smtp_url = 'smtp://$from@smtp.gmail.com:587/'" >> ~/.muttrc
echo "set smtp_pass = '$PASSWORD'" >> ~/.muttrc
echo "set move = no" >> ~/.muttrc
echo "set markers = no" >> ~/.muttrc
echo "set sort = 'threads'" >> ~/.muttrc
echo "set sort_aux = 'last-date-received'" >> ~/.muttrc

echo "Writing macros..."

echo "" >> ~/.muttrc
echo "bind editor <space> noop" >> ~/.muttrc
echo "macro index gi '<change-folder>=INBOX<enter>' 'Go to Inbox'" >> ~/.muttrc
echo "macro index ga '<change-folder>=[Gmail]/All Mail<enter>' 'Go to All Mail'" >> ~/.muttrc
echo "macro index gs '<change-folder>=[Gmail]/Sent Mail<enter>' 'Go to Sent Mail'" >> ~/.muttrc
echo "macro index gd '<change-folder>=[Gmail]/Drafts<enter>' 'Go to Drafts'" >> ~/.muttrc
echo "macro index gx '<change-folder>=[Gmail]/Spam<enter>' 'Go to Spam'" >> ~/.muttrc


echo ""
echo ""
echo "Done!"

echo "Hit [Enter] to launch Mutt!"
read mutt

mutt

exit 0;

