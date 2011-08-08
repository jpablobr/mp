#!/bin/bash

#	Usage:
#		new_script [ -h | --help ] [ [ -i ] [ -f file ] ]
#
#	Options:
#
#		-h, --help	Display this help message and exit.
#		-i		Prompt user for script information. This
#				includes a one line description of the
#				script, its command line options and
#				arguments.
#		-f file		Write output to file, otherwise output
#				is written to standard output.


###########################################################################
#	Constants and Global Variables
###########################################################################

PROGNAME=$(basename $0)
VERSION="2.1.0"
SCRIPTSHELL=${SHELL}
DEFAULT_SCRIPT_NAME=untitled_script
if [ -d ~/tmp ]; then
	TEMP_DIR=~/tmp
else
	TEMP_DIR=/tmp
fi
TEMP_FILE=$(mktemp -q "${TEMP_DIR}/${PROGNAME}.$$.XXXXXX")

# Make some pretty date strings
DATE=$(date +'%m/%d/%Y')
YEAR=$(date +'%Y')

# Get user's real name from passwd file
AUTHOR=$(awk -v USER=$USER 'BEGIN { FS = ":" } $1 == USER { print $5 }' < /etc/passwd)

# Construct the user's email address from the hostname (this works in
# RH Linux, but not in Solaris) or the REPLYTO environment variable, if defined
EMAIL_ADDRESS="<${REPLYTO:-${USER}@$(hostname)}>"

# Bring forth a few global variables
purpose="(describe purpose of script)"
root_user=
root_check=
security_considerations=


###########################################################################
#	Functions
###########################################################################

function clean_up
{

	#####
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${TEMP_FILE}
}


function graceful_exit
{
	#####
	#	Function called for a graceful exit
	#	No arguments
	#####

	clean_up
	exit
}


function error_exit
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	local err_msg

	err_msg="${PROGNAME}: ${1}"
	echo ${err_msg} >&2
	clean_up
	exit 1
}


function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}


function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Aborted by user"
	clean_up
	exit
}


function usage
{
	#####
	#	Function to display a usage message (does not exit)
	#	No arguments
	#####

	echo "Usage: ${PROGNAME} [-h | --help] | [ [-i] [-f file] ]"
}


function helptext
{
	#####
	#	Function to display help message for program
	#	No arguments
	#####

	local tab=$(echo -en "\t\t")

	cat <<- _EOF_

	${PROGNAME} ver. ${VERSION}
	This program creates a template for a shell program.

	$(usage)

	Options:

	-h, --help	Display this help message and exit.
	-i		Interactive mode.  Prompt user for
			${tab}script information.
	-f file		Write output to file, otherwise write
			${tab}output to standard output.

	_EOF_
}


function comment_bar_long
{
	#####
	#	Function to output a long comment bar
	#	No arguments
	#####


	echo "#	-------------------------------------------------------------------"
}


function comment_bar_short
{
	#####
	#	Function to output a short comment bar
	#	No arguments
	#####


	echo "#	-----"
}


function comment_text
{
	#####
	#	Function to output a comment string
	#	Arguments:
	#		1	comment string (optional)
	#####


	if [ -z "$1" ]
	then
		echo "#"
	else
		echo -e "#\t$1"
	fi

}


function set_shell
{
	#####
	#	Function to output first line of script indicating command interpreter
	#	No arguments
	#####


	echo -e "#!${SCRIPTSHELL}\n"

}


function section_header
{
	#####
	#	Function to output section header comment block
	#	Arguments:
	#		1	comment string (optional)
	#####


	echo -e "\n"
	comment_bar_long
	comment_text "$1"
	comment_bar_long
}


function ask_yes_no
{
	#####
	#	Function to ask a yes/no question
	#	Arguments:
	#		1	prompt string (optional)
	#####

	local yn=

	while [ "$yn" = "" ]; do
		echo -en "$1"
		read yn
		case $yn in
			y|Y)	yn=0 ;;
			n|N)	yn=1 ;;
			*)	yn=
				echo "Invalid response - please answer y or n"
				;;
		esac
	done
	return $yn
}


function script_header
{
	#####
	#	Function to output script header comment block
	#	Arguments:
	#		1	name of output file (optional)
	#####

	local output_file=$(basename ${1-$DEFAULT_SCRIPT_NAME})

	set_shell
	comment_bar_long
	comment_text
	comment_text "Shell program to ${purpose}."
	comment_text
	comment_text "Copyright ${YEAR}, ${AUTHOR} ${EMAIL_ADDRESS}."
	comment_text
	comment_text "This program is free software; you can redistribute it and/or"
	comment_text "modify it under the terms of the GNU General Public License as"
	comment_text "published by the Free Software Foundation; either version 2 of the"
	comment_text "License, or (at your option) any later version. "
	comment_text
	comment_text "This program is distributed in the hope that it will be useful, but"
	comment_text "WITHOUT ANY WARRANTY; without even the implied warranty of"
	comment_text "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU"
	comment_text "General Public License for more details."
	comment_text
	comment_text "Description:"
	comment_text
	comment_text
	if [ "${root_user}" != "" ]; then
		comment_text "${root_user}"
	fi
	if [ "${security_considerations}" != "" ]; then
		comment_text "${security_considerations}"
	fi
	comment_text
	comment_text "Usage:"
	comment_text
	comment_text "	${output_file} [ -h | --help ]${opt_usage}"
	comment_text
	comment_text "Options:"
	comment_text
	comment_text "	-h, --help	Display this help message and exit."
	echo -en "${opt_comment}"
	comment_text
	comment_text
	comment_text "Revision History:"
	comment_text
	comment_text "${DATE}	File created by new_script ver. $VERSION"
	comment_text
	comment_bar_long

}


function get_option_name
{
	#####
	#	Prompt user for name of command option
	#	Returns option name (via stdout)
	#	Arguments:
	#		1	option number (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then
		error_exit "get_option_name: missing argument 1"
	fi

	local foo

	while true; do
		echo -en "\nName of option ${1} [a-z] (return to quit): "
		read foo

		# If response is empty return empty opt_name.  We are done with options.
		if [ "$foo" = "" ]; then
			opt_name=""
			return
		else
			# Otherwise verify opt_name
			opt_name=$(echo $foo | awk '/^[a-gi-z]$/ { print $0 }')
			if [ "$opt_name" != "" ]; then
				break
			else
				echo "Invalid response.  Option must be single lowercase letter except 'h'."
			fi
		fi
	done

	# Get description of option
	echo -en "Description of option '${opt_name}': "
	read opt_desc

	# Get argument for option if required
	echo -en "Does option '${opt_name}' require an argument (like a file name) [y/n] -> "
	read foo
	if [ "$foo" = "y" ]; then
		arg_name=""
		while [ "$arg_name" = "" ]; do
			echo -en "Name of argument for option '${opt_name}': "
			read arg_name
		done
		opt_opt="${opt_opt}${opt_name}:"
	else
		arg_name=""
		opt_opt="${opt_opt}${opt_name}"
	fi
	if [ "$arg_name" = "" ]; then
		opt_usage="${opt_usage} [-${opt_name}]"
	else
		opt_usage="${opt_usage} [-${opt_name} ${arg_name}]"
	fi

}	# end of get_option_name


function interactive_prompting
{
	#####
	#	Prompt user for script information
	#	Arguments:
	#		none
	#####

	local opt_count

	echo -en "Purpose of this script is to: "
	read purpose

	if ask_yes_no "Does this script require superuser privileges to run? [y/n] --> "; then
		root_user="NOTE: You must be the superuser to run this script."
		root_check="root_check"
	fi

	if ask_yes_no "Does this script contain security information? [y/n] ---------> "; then
		security_considerations="WARNING!: Contains security info.  Do not set world-readable."
	fi

	opt_opt=":h"
	if ask_yes_no "\nDoes this script have command line options? [y/n] ------------> "; then
		opt_count=1

		# While there are options let's ask the user about them
		while [ $opt_count -gt 0 ]; do

			get_option_name $opt_count

			# If user just hits return, that means we are done asking about options
			if [ "$opt_name" != "" ]; then

				opt_comment="${opt_comment}$(printf "#\\\t\\\t%-4s%-12s%s\\\n" "-${opt_name}" "${arg_name}" "$opt_desc")"
				opt_help="${opt_help}$(printf "\\\t%-4s%-12s%s\\\n" "-${opt_name}" "${arg_name}" "$opt_desc")"
				if [ "$arg_name" = "" ]; then
					opt_case="${opt_case}$(printf "\\\t\\\t%1s )\\\techo \"%s\" ;;\\\n" "${opt_name}" "${opt_desc}")"
				else
					opt_case="${opt_case}$(printf "\\\t\\\t%1s )\\\techo \"%s - argument = %s\" ;;\\\n" "${opt_name}" "${opt_desc}" "\$OPTARG")"
				fi
				opt_count=$((opt_count + 1))
			else
				opt_count=0
			fi
		done
	fi

}	# end of interactive_prompting


function write_program
{
	#####
	#	Function to write body of program to stdout
	#	1 argument (optional)
	#		name of output file
	#####

	script_header $1


	# Create constants section

	section_header "Constants"

	cat << _EOF_

	PROGNAME=\$(basename \$0)
	VERSION="0.0.1"

_EOF_


	# Create functions section and define common functions

	section_header "Functions"

##########################################################
### PAY ATTENTION! WHAT FOLLOWS IS NOT PART OF THIS SCRIPT
### START OF "HERE" SCRIPT
##########################################################

	cat << _EOF_


function clean_up
{

#	-----------------------------------------------------------------------
#	Function to remove temporary files and other housekeeping
#		No arguments
#	-----------------------------------------------------------------------

	rm -f \${TEMP_FILE1}
}


function error_exit
{

#	-----------------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	-----------------------------------------------------------------------


	echo "\${PROGNAME}: \${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}


function graceful_exit
{

#	-----------------------------------------------------------------------
#	Function called for a graceful exit
#		No arguments
#	-----------------------------------------------------------------------

	clean_up
	exit
}


function signal_exit
{

#	-----------------------------------------------------------------------
#	Function to handle termination signals
#		Accepts 1 argument:
#			signal_spec
#	-----------------------------------------------------------------------

	case \$1 in
		INT)	echo "\$PROGNAME: Program aborted by user" >&2
			clean_up
			exit
			;;
		TERM)	echo "\$PROGNAME: Program terminated" >&2
			clean_up
			exit
			;;
		*)	error_exit "\$PROGNAME: Terminating on unknown signal"
			;;
	esac
}


function make_temp_files
{

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

	TEMP_FILE1=\$(mktemp -q "\${TEMP_DIR}/\${PROGNAME}.\$\$.XXXXXX")
	if [ "\$TEMP_FILE1" = "" ]; then
		error_exit "cannot create temp file!"
	fi
}


function usage
{

#	-----------------------------------------------------------------------
#	Function to display usage message (does not exit)
#		No arguments
#	-----------------------------------------------------------------------

	echo "Usage: \${PROGNAME} [-h | --help]${opt_usage}"
}


function helptext
{

#	-----------------------------------------------------------------------
#	Function to display help message for program
#		No arguments
#	-----------------------------------------------------------------------

	local tab=\$(echo -en "\t\t")

	cat <<- -EOF-

	\${PROGNAME} ver. \${VERSION}
	This is a program to ${purpose}.

	\$(usage)

	Options:

	-h, --help	Display this help message and exit.
$(echo -en "${opt_help}")

	${root_user}
	${security_considerations}
-EOF-
}
_EOF_

##########################################################
### END OF "HERE" SCRIPT
##########################################################

	if [ "$root_check" = "root_check" ]; then
		cat << _EOF_


function root_check
{
	#####
	#	Function to check if user is root
	#	No arguments
	#####

	if [ "\$(id | sed 's/uid=\\([0-9]*\\).*/\\1/')" != "0" ]; then
		error_exit "You must be the superuser to run this script."
	fi
}
_EOF_
	fi



	# Create main section and set up traps

	section_header "Program starts here"

##########################################################
### PAY ATTENTION! WHAT FOLLOWS IS NOT PART OF THIS SCRIPT
### START OF "HERE" SCRIPT
##########################################################

	cat << _EOF_

##### Initialization And Setup #####

# Set file creation mask so that all files are created with 600 permissions.

umask 066
$root_check

# Trap TERM, HUP, and INT signals and properly exit

trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Create temporary file(s)

make_temp_files


##### Command Line Processing #####

if [ "\$1" = "--help" ]; then
	helptext
	graceful_exit
fi

while getopts "$opt_opt" opt; do
	case \$opt in
$(echo -en "${opt_case}")
		h )	helptext
			graceful_exit ;;
		* )	usage
			clean_up
			exit 1
	esac
done


##### Main Logic #####

graceful_exit

_EOF_

##########################################################
### END OF "HERE" SCRIPT
##########################################################

}


###########################################################################
#	Program starts here
###########################################################################

# Trap TERM, HUP, and INT signals and properly exit

trap term_exit TERM HUP
trap int_exit INT

# Process command line arguments

if [ "$1" = "--help" ]; then
	helptext
	graceful_exit
fi

file_flag=0
interactive_flag=0

while getopts ":hif:" opt; do
	case $opt in
		f )	file_flag=1
			output_file=${OPTARG}
			;;
		i )	interactive_flag=1
			;;
		h )	helptext
			graceful_exit
			;;
		* )	usage
			exit 1
	esac
done

if [ $file_flag = 1 ] ; then
	# See if output file already exists
	if [ -e "${output_file}" ] ; then
		# Make sure it's a regular file
		if [ -f "${output_file}" ] ; then
			# Is it writable?
			if [ -w "${output_file}" ]; then
				# Confirm overwrite
				if ! ask_yes_no "Output file exists - Overwrite? [y/n] "; then
					int_exit
				fi
			else
				error_exit "Output file is not writable"
			fi
		else
			error_exit "Output file is not a regular file"
		fi
	else
		# Try and write it
		touch "${output_file}" || error_exit "Cannot write output file"
		chmod 700 "${output_file}" || error_exit "Unable to set permissions on output file"
	fi
	if [ $interactive_flag = 1 ]; then
		interactive_prompting
	fi
	write_program  $output_file > $output_file
else
	if [ $interactive_flag = 1 ]; then
		interactive_prompting
	fi
	write_program
fi

graceful_exit