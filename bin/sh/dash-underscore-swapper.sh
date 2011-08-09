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
	-rd,   $(tput setaf 2 bold) Dash2underscore all files in current directory recursivly.$(tput op)
	-ru,   $(tput setaf 2 bold) Udescore2dash all files in current directory recursively.$(tput op)
	-d2u,  $(tput setaf 2 bold) Dash2underscore the given file.$(tput op)
	-u2d,  $(tput setaf 2 bold) Underscore2dash the give file.$(tput op)

-EOF-
}

dash2underscore() {
#	-----------------------------------------------------------------------
#	Rename the given file from dashs to underscores and downcase them.
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

underscore2dash() {
#	-----------------------------------------------------------------------
#	Rname the given file from dashs to underscores and downcase them.
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
                underscore2dash $f
            fi
        done
    elif [[ "$1" = "d" ]]; then
        for f in `find . -maxdepth 1 | cut -c 3-`; do
            if [[ $f != "./" ]] && [[ "$f" =~ '-' ]]; then
                dash2underscore $f
            fi
        done
    fi
}

#	-------------------------------------------------------------------
#	Program starts here
#	-------------------------------------------------------------------

[[ ! "$1" ]] && helptext

while [ -n "$1" ]; do
    case $1 in
        -h) helptext ;;
        -ru) change-recursively "u"; shift ;;
        -rd) change-recursively "d"; shift ;;
        -u2d) underscore2dash "$2"; shift ;;
        -d2u) dash2underscore "$2"; shift ;;
        *) helptext; break;;
    esac
done

exit 0