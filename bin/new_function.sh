#!/bin/bash

#	Usage:
#
#		new_function [ -h | --help ] [-f file]
#
#	Options:
#
#		-h, --help	Display this help message and exit.
#		-f file		Write output to file, otherwise output
#				is written to standard output.
#

###########################################################################
#	Constants
###########################################################################

PROGNAME=$(basename $0)
TEMP_FILE=/tmp/${PROGNAME}.$$.$RANDOM


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
	#	Function to display usage message (does not exit)
	#	No arguments
	#####

	echo "Usage: ${PROGNAME} [-h | --help] [-f file]"
}


function helptext
{
	#####
	#	Function to display help message for program
	#	No arguments
	#####

	local tab=$(echo -en "\t\t")

	cat <<- -EOF-

	This is a program to create function templates.

	$(usage)

	Options:

	-h, --help	Display this help message and exit.
	-f file		Write output to file, otherwise output
			${tab}is written to standard output.

	-EOF-
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


function write_function
{
	#####
	# Constructs and outputs function template
	# Arguments:
	#	none
	#####

	local function_name
	local description
	local arg_count=0
	local arg_desc
	local optional
	local arg_test

	echo -en "Name of function: "
	read function_name

	echo -e "\nfunction ${function_name}" > $TEMP_FILE
	echo -e "{\n" >> $TEMP_FILE
	echo "#	------------------------------------------------------------------------" >> $TEMP_FILE

	echo -en "Description of function: "
	read description

	echo "#	${description}" >> $TEMP_FILE
	echo "#		Arguments:" >> $TEMP_FILE

	if ask_yes_no "Does this function have arguments? [y/n]: "; then
		arg_count=1

		# While there are arguments let's ask the user about them
		while [ $arg_count -gt 0 ]; do

			echo -en "Description of argument ${arg_count} (return to quit): "
			read arg_desc

			# If user just hit return, that means we are done asking about arguments
			if [ "$arg_desc" != "" ]; then

				# Once we get an optional argument, all remaining args must be optional
				if [ "$optional" != "(optional)" ]; then

					if ask_yes_no "Is argument ${arg_count} optional? [y/n]: "; then
						optional="(optional)"
					else
						# if argument is required, we construct a test for it in the code
						optional="(required)"
						arg_test="${arg_test}$(echo -en "\n\tif [ \"\$$arg_count\" = \"\" ]; then \n\t\terror_exit \"${function_name}: missing argument ${arg_count}\"\n\tfi")"
					fi
				fi
				echo "#			$arg_count	$arg_desc ${optional}" >> $TEMP_FILE

				arg_count=$((arg_count + 1))
			else
				arg_count=0
			fi
		done
	else
		echo "#			none" >> $TEMP_FILE
	fi

	echo -e "#	------------------------------------------------------------------------\n" >> $TEMP_FILE

	# If there are required arguments, put in the tests
	if [ "$arg_test" != "" ]; then
		echo -e "\t# Fatal error if required arguments are missing"  >> $TEMP_FILE
		echo -e "$arg_test\n" >> $TEMP_FILE
	fi
	echo -e "	return\n" >> $TEMP_FILE
	echo -e "}	# end of $function_name\n" >> $TEMP_FILE

}	# end of write_function


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

while getopts ":hf:" opt; do
	case $opt in
		f )	file_flag=1
			output_file=${OPTARG}

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
			fi ;;
		h )	helptext
			graceful_exit ;;
		* )	usage
			exit 1
	esac
done

# Do all the real work here
write_function

# Are we writing output to a file?
if [ $file_flag = 1 ]; then
	cp $TEMP_FILE $output_file
else
	cat $TEMP_FILE
fi

graceful_exit
