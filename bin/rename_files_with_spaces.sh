#!/bin/bash

#	-------------------------------------------------------------------
#
#	Shell program to rename files with spaces or dashes with underscores.
#
#	Copyright 2011, jpablobr <xjpablobr@gmail.com>
#
#	This program is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License as
#	published by the Free Software Foundation; either version 2 of the
#	License, or (at your option) any later version.
#
#	This program is distributed in the hope that it will be useful, but
#	WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#	General Public License for more details.
#
#	Description:
#
#	  Shell program to rename files with spaces or dashes with underscores.
#   are changed to underscores
#
#	Usage:
#
#   find . -depth -exec ~/bin/rename_files_with_spaces {} \;
#
#	Revision History:
#
#	-------------------------------------------------------------------
#	Constants
#	-------------------------------------------------------------------

	PROGNAME=$(basename $0)
	VERSION="0.0.1"

#	-------------------------------------------------------------------
#	Functions
#	-------------------------------------------------------------------

function clean_up {
#	-----------------------------------------------------------------------
#	Function to remove temporary files and other housekeeping
#		No arguments
#	-----------------------------------------------------------------------
	rm -f ${TEMP_FILE1}
}

function error_exit {
#	-----------------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	-----------------------------------------------------------------------
	echo "${PROGNAME}: ${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}

function graceful_exit {
#	-----------------------------------------------------------------------
#	Function called for a graceful exit
#		No arguments
#	-----------------------------------------------------------------------
	clean_up
	exit
}

function signal_exit {
#	-----------------------------------------------------------------------
#	Function to handle termination signals
#		Accepts 1 argument:
#			signal_spec
#	-----------------------------------------------------------------------
	case $1 in
		INT)	echo "$PROGNAME: Program aborted by user" >&2
			clean_up
			exit
			;;
		TERM)	echo "$PROGNAME: Program terminated" >&2
			clean_up
			exit
			;;
		*)	error_exit "$PROGNAME: Terminating on unknown signal"
			;;
	esac
}


function make_temp_files {
#	-----------------------------------------------------------------------
#	Function to create temporary files
#		No arguments
#	-----------------------------------------------------------------------
	# Use user's local tmp directory if it exists

	if [ -d ~/tmp ]; then
		TEMP_DIR=~/tmp
	else
		TEMP_DIR=/tmp
	fi

	# Temp file for this script, using paranoid method of creation to
	# insure that file name is not predictable.  This is for security to
	# avoid "tmp race" attacks.  If more files are needed, create using
	# the same form.
	TEMP_FILE1=$(mktemp -q "${TEMP_DIR}/${PROGNAME}.$$.XXXXXX")
	if [ "$TEMP_FILE1" = "" ]; then
		error_exit "cannot create temp file!"
	fi
}

function usage {
#	-----------------------------------------------------------------------
#	Function to display usage message (does not exit)
#		No arguments
#	-----------------------------------------------------------------------
	echo "Usage: ${PROGNAME} [-h | --help]"
}


function helptext {
#	-----------------------------------------------------------------------
#	Function to display help message for program
#		No arguments
#	-----------------------------------------------------------------------
	local tab=$(echo -en "\t\t")

	cat <<- -EOF-

	${PROGNAME} ver. ${VERSION}
  This will rename all files in the directory so that the spaces in filenames

	$(usage)

	Options:

	-h, --help	Display this help message and exit.

-EOF-
}

function rename_files {
#	-----------------------------------------------------------------------
#	Function to rename files with spaces to underscores and downcase them.
#		No arguments
#	-----------------------------------------------------------------------
    org_name="$1"
    dir=`dirname "$1"`
    file=`basename "$1"`

    new_file_name=`echo  $file|sed "s/[ |-]/_/g" | tr '[:upper:]' '[:lower:]'`
    new_name=$dir"/"$new_file_name

    if [ "$org_name" != "$new_name" ]; then
        mv "$org_name" "$new_name"
        echo "New file name: $new_name"
    fi

}

#	-------------------------------------------------------------------
#	Program starts here
#	-------------------------------------------------------------------

##### Initialization And Setup #####

# Set file creation mask so that all files are created with 600 permissions.

umask 066

# Trap TERM, HUP, and INT signals and properly exit

trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Create temporary file(s)

make_temp_files

##### Command Line Processing #####

if [ "$1" = "--help" ]; then
	helptext
	graceful_exit
fi

while getopts ":hd:" opt; do
	case $opt in

		h )	helptext
			graceful_exit ;;
		* )	usage
			clean_up
			exit 1
	esac
done

##### Main Logic #####
rename_files "$1"
graceful_exit
