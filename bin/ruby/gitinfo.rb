#!/usr/bin/env ruby

# This script is based on the git-info shell script from Duane Johnson.
# I like the ruby flavour, so i rebuild it in ruby. :)

until File.directory? ".git" do
  Dir.chdir ".." if Dir.pwd != "/"
end

abort "Not a git repository (or any of the parent directories): .git" unless File.directory? ".git"

puts "== Remote URL: #{`git remote -v`}"
puts "== Remote Branches:"
puts `git branch -r --color`
puts "== Local Branches:"
puts `git branch --color`
puts "== Configuration (.git/config)"
puts `cat .git/config` 
puts "== Most Recent Commit"
puts `git log -1 --color`