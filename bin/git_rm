#!/bin/bash
# Completely removes a given file from a git repo

git filter-branch --index-filter 'git rm --cached --ignore-unmatch $1' HEAD
git push origin master --force
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now

