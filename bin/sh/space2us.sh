#!/usr/bin/env bash

function helptext {
#	-----------------------------------------------------------------------
#	Display help message.
#		No arguments
#	-----------------------------------------------------------------------
	local tab=$(echo -en "\t\t")

	cat <<- -EOF-

$(tput setaf 2 bold)Swaps file(s) "-" and "_" characters, and downcase them as well recursively.$(tput op)

	Options:

	-h,    $(tput setaf 2 bold) Display this help message and exit.$(tput op)
	-rs,   $(tput setaf 2 bold) Space2underscore all files in current directory recursivly.$(tput op)
	-ru,   $(tput setaf 2 bold) Udescore2space all files in current directory recursively.$(tput op)
	-s2u,  $(tput setaf 2 bold) Space2underscore the given file.$(tput op)
	-u2s,  $(tput setaf 2 bold) Underscore2space the give file.$(tput op)

-EOF-
}

space2underscore() {
#	-----------------------------------------------------------------------
#	Rename the given file from spaces to underscores and downcase them.
#		Name of the file.
#	-----------------------------------------------------------------------
    local file=`basename "$1"`
    local nf=`echo  $file|sed "s/[ |-]/_/g" | tr '[:upper:]' '[:lower:]'`

    if [ "$1" != "$nf" ]; then
        mv "$1" "$nf"
        tput setaf 2 bold
        echo "$1 new name: $nf"
        tput op
    fi
}

underscore2space() {
#	-----------------------------------------------------------------------
#	Rname the given file from spaces to underscores and downcase them.
#		Name of the file.
#	-----------------------------------------------------------------------
    local file=`basename "$1"`
    local nf=`echo  $file|sed "s/[ |_]/-/g" | tr '[:upper:]' '[:lower:]'`
    if [ "$1" != "$nf" ]; then
        mv "$1" "$nf"
        tput setaf 2 bold
        echo "$1 new name: $nf"
        tput op
    fi
}

change-recursively() {
#	------------------------------------------------------------------
#	Recursiverly rename files
#		No arguments
#	------------------------------------------------------------------
    if [[ "$1" = "u" ]]; then
        for f in `find . -maxdepth 1 | cut -c 3-`; do
            if [[ $f != "./" ]] && [[ "$f" =~ '_' ]]; then
                underscore2space $f
            fi
        done
    elif [[ "$1" = "s" ]]; then
        for f in `find . -maxdepth 1 | cut -c 3-`; do
            if [[ $f != "./" ]] && [[ "$f" =~ '-' ]]; then
                space2underscore $f
            fi
        done
    fi
}

#	-------------------------------------------------------------------
#	Program starts here
#	-------------------------------------------------------------------

[[ ! "$1" ]] && helptext

# The option parser, change it as needed
# In this example -f and -h take no arguments -l takes an argument
# after the l
while [ -n "$1" ]; do
    case $1 in
        -h) helptext ;;
        -ru) change-recursively "u"; shift ;;
        -rs) change-recursively "s"; shift ;;
        -u2s) underscore2space "$2"; shift ;;
        -s2u) space2underscore "$2"; shift ;;
        *) helptext; break;;
    esac
done

exit 0