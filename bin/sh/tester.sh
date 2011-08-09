#!/usr/bin/env bash
# tester.sh
# Testing template
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 29 Apr 2011

# cat /etc/passwd |
# awk '
#     BEGIN     { FS = ":" }
#     /^[a-z_]/ { print $1 }
# '
curl -s http://www.gutenberg.org/files/1080/1080.txt |
awk '
    BEGIN { FS="[^a-zA-Z]+" }

    {
        for (i=1; i<=NF; i++) {
            word = tolower($i)
            words[word]++
        }
    }

    END {
        for (w in words)
             printf("%3d %s\n", words[w], w)
    }
' |
sort -rn