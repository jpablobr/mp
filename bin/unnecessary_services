#!/bin/sh
# in order to remove unnecessary services, first determine how is it started and
# which package provides it. You can do this easily by checking the program that
# listens in the socket, the following example will tell you using this tools and
# dpkg
# http://www.cercy.net/debian/securing/apA.en.html
# FIXME: this is quick and dirty; replace with a more robust script snippet

for i in `sudo lsof -i | grep LISTEN | cut -d " " -f 1 |sort -u` ; do
     pack=`dpkg -S $i |grep bin |cut -f 1 -d : | uniq`
     echo "Service $i is installed by $pack";
     init=`dpkg -L $pack |grep init.d/ `
     if [ ! -z "$init" ]; then
              echo "and is run by $init"
     fi
done