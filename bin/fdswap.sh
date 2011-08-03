#!/bin/bash
#
#
# Usage:  <old logfile>  <new logfile> [ optional pids ]
#         ./swap.sh /var/log/logfile /tmp/logfile  [pids]
#
# Author: Robert McKay <rob...@mckay.com>
# Date:   Tue Aug 14 13:36:35 BST 2007
# url: http://bit.ly/eEYfp5

if [ "$2" = "" ]; then
    echo "Usage: $0 /path/to/oldfile /path/to/newfile [pids]
Example: $0 /var/log/somedaemon.log /var/log/newvolume/somedaemon.log 1234
Example: $0 /dev/pts/53 /dev/null 1234
"
    exit 0
fi

if gdb --version > /dev/null 2>&1; then
   true
else
    echo "Unable to find gdb."
    exit 1
fi

src=$1
dst=$2
shift; shift
pids=$*

for pid in ${pids:=$( /sbin/fuser $src | cut -d ':' -f 2 )};
do
    echo "src=$src, dst=$dst"
    echo "$src has $pid using it"
    (
            echo "attach $pid"
        echo 'call open("'$dst'", 66, 0666)'
        for ufd in $(LANG=C ls -l /proc/$pid/fd | grep $src\$ | awk ' { print $9; } ');
            do
            echo 'call dup2($1,'"$ufd"')'
        done
        echo 'call close($1)'
        echo 'detach'
        echo 'quit'
        sleep 5
    ) | gdb -q -x -
done