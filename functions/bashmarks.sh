# Copyright (c) 2010, Huy Nguyen, http://www.huyng.com
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice, this list of conditions
#       and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#       following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of Huy Nguyen nor the names of contributors
#       may be used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# USAGE:
#    gt-s bookmarkname - saves the curr dir as bookmarkname
#	 gt bookmarkname - jumps to the that bookmark
#	 gt-g b[TAB] - tab completion is available
#	 gt-p bookmarkname - prints the bookmark
#	 gt-p b[TAB] - tab completion is available
#	 gt-d bookmarkname - deletes the bookmark
#	 gt-d [TAB] - tab completion is available
#	 gt-l - list all bookmarks

# File to store bookmarks
if [ ! -n "$SDIRS" ]; then
    SDIRS=~/.sdirs
fi
touch $SDIRS

# save current directory to bookmarks
function gt-s {
	check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
	cat $SDIRS | grep -v "export DIR_$1=" > $SDIRS.tmp
	mv $SDIRS.tmp $SDIRS
	echo "export DIR_$1='$PWD'" >> $SDIRS
    fi
}

# I think of them as gotos
function gt {
	check_help $1
    source $SDIRS
    cd "$(eval $(echo echo $(echo \$DIR_$1)))"
}

# print bookmark
function gt-p {
	check_help $1
    source $SDIRS
    echo "$(eval $(echo echo $(echo \$DIR_$1)))"
}

# delete bookmark
function gt-d {
	check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
	cat $SDIRS | grep -v "export DIR_$1=" > $SDIRS.tmp
	mv $SDIRS.tmp $SDIRS
	unset "DIR_$1"
    fi
}

# print out help for the forgetful
function check_help {
	if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
		echo ''
	    echo 'gt-s <bookmark_name> - Saves the current directory as "bookmark_name"'
	    echo 'gt <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
	    echo 'gt-p <bookmark_name> - Prints the directory associated with "bookmark_name"'
	    echo 'gt-d <bookmark_name> - Deletes the bookmark'
	    echo 'gt-l                 - Lists all available bookmarks'
		kill -SIGINT $$
	fi
}

# list bookmarks with dirnam
function gt-l {
	check_help $1
	source $SDIRS
	env | grep "^DIR_" | cut -c5- | grep "^.*="
}

# list bookmarks without dirname
function _l {
    source $SDIRS
    env | grep "^DIR_" | cut -c5- | grep "^.*=" | cut -f1 -d "="
}

# validate bookmark name
function _bookmark_name_valid {
    exit_message=""
    if [ -z $1 ]; then
		exit_message="bookmark name required"
		echo $exit_message
	elif [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
		exit_message="bookmark name is not valid"
		echo $exit_message
    fi
}

# completion command
function _comp {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W '`_l`' -- $curw))
    return 0
}

# bind completion command
# for: gt,gt-p,gt-d to _comp
shopt -s progcomp
complete -F _comp gt
complete -F _comp gt-p
complete -F _comp gt-d